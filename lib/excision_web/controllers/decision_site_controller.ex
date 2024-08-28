defmodule ExcisionWeb.DecisionSiteController do
  use ExcisionWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias Excision.Excisions
  alias Excision.Excisions.DecisionSite

  tags ["decision_sites"]

  action_fallback ExcisionWeb.FallbackController

  operation :index,
    summary: "List decision sites",
    description: "List all decision sites"

  def index(conn, _params) do
    decision_sites = Excisions.list_decision_sites()
    render(conn, :index, decision_sites: decision_sites)
  end

  operation :create,
    summary: "Create decision site",
    description: "Create a new decision site"

  def create(conn, %{"decision_site" => decision_site_params}) do
    with {:ok, %DecisionSite{} = decision_site} <-
           Excisions.create_decision_site(decision_site_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/decision_sites/#{decision_site}")
      |> render(:show, decision_site: decision_site)
    end
  end

  operation :show,
    summary: "Show decision site",
    description: "Show a decision site"

  def show(conn, %{"id" => id}) do
    decision_site = Excisions.get_decision_site!(id)
    render(conn, :show, decision_site: decision_site)
  end

  operation :update,
    summary: "Update decision site",
    description: "Update a decision site"

  def update(conn, %{"id" => id, "decision_site" => decision_site_params}) do
    decision_site = Excisions.get_decision_site!(id)

    with {:ok, %DecisionSite{} = decision_site} <-
           Excisions.update_decision_site(decision_site, decision_site_params) do
      render(conn, :show, decision_site: decision_site)
    end
  end

  operation :delete,
    summary: "Delete decision site",
    description: "Delete a decision site"

  def delete(conn, %{"id" => id}) do
    decision_site = Excisions.get_decision_site!(id)

    with {:ok, %DecisionSite{}} <- Excisions.delete_decision_site(decision_site) do
      send_resp(conn, :no_content, "")
    end
  end

  operation :invoke,
    summary: "Invoke decision site",
    description: "Invoke a decision site"

  def invoke(conn, %{"id" => id}) do
    decision_site = Excisions.get_decision_site!(id, preloads: [:active_classifier])

    if decision_site.active_classifier.name == "baseline" do
      proxy_openai_structured_response(conn, decision_site)
    else
      classifier = decision_site.active_classifier

      # TODO: this is really slow, need GenServer (Agent?) to keep model in memory
      model_name = "distilbert/distilbert-base-uncased"

      {:ok, spec} =
        Bumblebee.load_spec({:hf, model_name},
          architecture: :for_sequence_classification
        )

      model = Bumblebee.build_model(spec)
      {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, model_name})
      checkpoint_path = classifier.checkpoint_path
      {:ok, checkpoints} = File.ls(checkpoint_path)
      last_checkpoint = checkpoints |> Enum.max()

      params =
        [checkpoint_path, last_checkpoint]
        |> Path.join()
        |> File.read!()
        |> Axon.Loop.deserialize_state()
        |> then(& &1.step_state.model_state)

      input = Jason.encode!(conn.body_params["messages"])
      outputs = Axon.predict(model, params, Bumblebee.apply_tokenizer(tokenizer, input))
      probs = outputs.logits |> Nx.sigmoid()
      prediction_idx = probs |> Nx.argmax(axis: 1) |> then(& &1[0]) |> Nx.to_number()

      label_map = %{true => 1, false => 0}
      idx_to_label = Map.new(label_map, fn {k, v} -> {v, k} end)
      prediction = idx_to_label[prediction_idx]

      # record the decision
      Excision.Excisions.create_decision(%{
        decision_site_id: decision_site.id,
        classifier_id: decision_site.active_classifier.id,
        input: input,
        prediction: prediction
      })

      send_resp(
        conn,
        :ok,
        Jason.encode!(%{
          choices: [
            %{
              message: %{
                role: "assistant",
                content: Jason.encode!(%{value: prediction})
              }
            }
          ]
        })
      )
    end
  end

  defp proxy_openai_structured_response(conn, decision_site) do
    # modify the body to add the response_format
    {raw_body, conn} = ReverseProxyPlug.read_body(conn)

    req_body =
      raw_body
      |> Jason.decode!()
      |> Map.put(
        "response_format",
        %{
          type: "json_schema",
          json_schema: %{
            name: "Decision",
            schema: %{
              type: "object",
              properties: %{
                value: %{
                  type: "boolean"
                }
              }
            }
          }
        }
      )

    new_body = req_body |> Jason.encode!()

    conn =
      conn
      |> assign(:raw_body, new_body)
      |> put_req_header("content-length", byte_size(new_body) |> Integer.to_string())

    opts =
      ReverseProxyPlug.init(
        client: ReverseProxyPlug.HTTPClient.Adapters.Req,
        client_options: [pool_timeout: 5000],
        upstream: Application.get_env(:excision, :openai_chat_completions_url),
        response_mode: :buffer,
        # don't send the host header to the upstream
        preserve_host_header: false
      )

    resp =
      conn
      # strip path, by default this is appended when proxying
      |> Map.put(:path_info, [])
      |> ReverseProxyPlug.call(opts)

    # parse response and record decision
    resp_body =
      resp.resp_body
      |> then(
        case Plug.Conn.get_resp_header(resp, "content-encoding") do
          ["gzip"] -> &:zlib.gunzip/1
          _ -> fn x -> x end
        end
      )
      |> Jason.decode!()

    # record the decision
    Excision.Excisions.create_decision(%{
      decision_site_id: decision_site.id,
      classifier_id: decision_site.active_classifier.id,
      input: Jason.encode!(req_body["messages"]),
      prediction:
        resp_body["choices"]
        |> Enum.at(0)
        |> then(& &1["message"]["content"])
        |> Jason.decode!()
        |> then(& &1["value"])
    })

    resp
  end
end
