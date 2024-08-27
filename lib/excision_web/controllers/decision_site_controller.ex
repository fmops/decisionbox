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
      # modify the body to add the response_format
      {raw_body, conn} = ReverseProxyPlug.read_body(conn)
      new_body = 
          raw_body
          |> Enum.at(0)
          |> Jason.decode!()
          |> Map.put(
          "response_format",  %{
            type: "json_schema",
            json_schema: %{
              name: "Decision",
              schema: %{
                type: "object",
                properties: %{
                  value: %{
                    type: "boolean"
                  }
                },
              }
            }
          })
          |> Jason.encode!()

      conn = conn
      |> assign(:raw_body, new_body)
        |> put_req_header("content-length", byte_size(new_body) |> Integer.to_string())

      opts = ReverseProxyPlug.init([
        client: ReverseProxyPlug.HTTPClient.Adapters.Req,
        client_options: [pool_timeout: 5000],
        upstream: "https://api.openai.com/v1/chat/completions",
        preserve_host_header: false # don't send the host header to the upstream
      ])

      conn
      |> Map.put(:path_info, []) # strip path, by default this is appended when proxying
      |> ReverseProxyPlug.call(opts)
    else
      IO.inspect("TODO: invoke non-baseline classifier")
      send_resp(conn, :not_implemented, "")
    end

  end
end
