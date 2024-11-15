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
    description: "Invoke a decision site's default classifier to make a decision"

  def invoke(conn, %{"id" => id}) do
    decision_site = Excisions.get_decision_site!(id, preloads: [:promoted_classifier, :choices])

    ExcisionWeb.ClassifierController.invoke(conn, %{"id" => decision_site.promoted_classifier.id})
  end
end
