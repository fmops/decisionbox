defmodule ExcisionWeb.ClassifierController do
  use ExcisionWeb, :controller
  use OpenApiSpex.ControllerSpecs

  require Logger

  alias Excision.Excisions
  alias Excision.Excisions.Classifier
  alias Excision.Util

  action_fallback ExcisionWeb.FallbackController

  tags ["classifiers"]

  operation :index,
    summary: "List classifiers",
    description: "List all classifiers"

  def index(conn, _params) do
    classifiers = Excisions.list_classifiers()
    render(conn, :index, classifiers: classifiers)
  end

  operation :create,
    summary: "Create classifier",
    description: "Create a new classifier"

  def create(conn, %{"classifier" => classifier_params}) do
    with {:ok, %Classifier{} = classifier} <- Excisions.create_classifier(classifier_params) do
      conn
      |> put_status(:created)
      |> put_resp_header(
        "location",
        ~p"/api/decision_sites/#{classifier.decision_site_id}/classifiers/#{classifier}"
      )
      |> render(:show, classifier: classifier)
    end
  end

  operation :show,
    summary: "Show classifier",
    description: "Show a classifier"

  def show(conn, %{"id" => id}) do
    classifier = Excisions.get_classifier!(id)
    render(conn, :show, classifier: classifier)
  end

  operation :update,
    summary: "Update classifier",
    description: "Update a classifier"

  def update(conn, %{"id" => id, "classifier" => classifier_params}) do
    classifier = Excisions.get_classifier!(id)

    with {:ok, %Classifier{} = classifier} <-
           Excisions.update_classifier(classifier, classifier_params) do
      render(conn, :show, classifier: classifier)
    end
  end

  operation :delete,
    summary: "Delete classifier",
    description: "Delete a classifier"

  def delete(conn, %{"id" => id}) do
    classifier = Excisions.get_classifier!(id)

    with {:ok, %Classifier{}} <- Excisions.delete_classifier(classifier) do
      send_resp(conn, :no_content, "")
    end
  end

  operation :invoke,
    summary: "Invoke classifier",
    description: "Invoke a classifier"

  def invoke(conn, %{"id" => id}) do
    classifier = Excisions.get_classifier!(id)

    decision_site =
      Excisions.get_decision_site!(classifier.decision_site_id, preloads: [:choices])

    if Excisions.is_default_passthrough_classifier?(classifier) do
      proxy_openai_structured_response(conn, classifier, decision_site)
    else
      # TODO: this is really slow, need GenServer (Agent?) to keep model in memory
      # TODO: read model name from classifier
      model_name = classifier.base_model_name
      repository = Util.build_bumblebee_model_repository(model_name)

      {:ok, tokenizer} = Bumblebee.load_tokenizer(repository)
      checkpoint_path = classifier.checkpoint_path

      {:ok, spec} =
        Bumblebee.load_spec({:hf, model_name},
          architecture: :for_sequence_classification
        )

      num_labels = decision_site.choices |> Enum.count()
      spec = Bumblebee.configure(spec, num_labels: num_labels)
      {:ok, model} = Bumblebee.load_model(repository, spec: spec)

      params =
        [checkpoint_path, "parameters.nx"]
        |> Path.join()
        |> File.read!()
        |> Nx.deserialize()

      input = Jason.encode!(conn.body_params["messages"])
      outputs = Axon.predict(model.model, params, Bumblebee.apply_tokenizer(tokenizer, input))
      probs = outputs.logits |> Nx.sigmoid()
      prediction_idx = probs |> Nx.argmax(axis: 1) |> then(& &1[0]) |> Nx.to_number()

      label_map = Excisions.build_label_map(decision_site)
      idx_to_label = Map.new(label_map, fn {k, v} -> {v, k} end)
      prediction = idx_to_label[prediction_idx]

      # record the decision
      {:ok, _} =
        Excision.Excisions.create_decision(%{
          decision_site_id: decision_site.id,
          classifier_id: classifier.id,
          input: input,
          prediction_id:
            decision_site.choices |> Enum.find(&(&1.name == prediction)) |> then(& &1.id)
        })

      conn
      |> put_resp_header("content-type", "application/json")
      |> send_resp(
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

  defp proxy_openai_structured_response(conn, classifier, decision_site) do
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
                  enum: decision_site.choices |> Enum.map(& &1.name)
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

    conn =
      conn
      # strip path, by default this is appended when proxying
      |> Map.put(:path_info, [])
      |> ReverseProxyPlug.call(opts)

    # parse response and record decision
    resp_body =
      if conn.status >= 400 do
        Logger.error(
          "Got failure response while proxying request for classifier #{classifier.name}: #{conn.status} #{conn.resp_body}"
        )

        {:error, conn.resp_body}
      else
        case Plug.Conn.get_resp_header(conn, "content-encoding") do
          ["gzip"] ->
            {:ok, :zlib.gunzip(conn.resp_body)}

          ["br"] ->
            :brotli.decode(conn.resp_body)

          _ ->
            {:ok, conn.resp_body}
        end
      end

    case resp_body do
      {:ok, _} ->
        deserialized_body = resp_body |> elem(1) |> Jason.decode!()

        # record the decision
        Excision.Excisions.create_decision(%{
          decision_site_id: decision_site.id,
          classifier_id: classifier.id,
          input: Jason.encode!(req_body["messages"]),
          prediction_id:
            decision_site.choices
            |> Enum.find(fn c ->
              c.name ==
                deserialized_body["choices"]
                |> hd()
                |> then(& &1["message"]["content"])
                |> then(&Jason.decode!/1)
                |> then(& &1["value"])
            end)
            |> then(& &1.id)
        })

      {:error, _} ->
        nil
    end

    conn
  end
end
