defmodule ExcisionWeb.DecisionController do
  use ExcisionWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias Excision.Excisions
  alias Excision.Excisions.Decision

  tags ["decisions"]

  action_fallback ExcisionWeb.FallbackController

  operation :index,
    summary: "List decisions",
    description: "List all decisions"

  def index(conn, _params) do
    decisions = Excisions.list_decisions()
    render(conn, :index, decisions: decisions)
  end

  operation :create,
    summary: "Create decision",
    description: "Create a new decision"

  def create(conn, %{"decision" => decision_params}) do
    with {:ok, %Decision{} = decision} <- Excisions.create_decision(decision_params) do
      decision = Excisions.get_decision!(decision.id, preloads: [:prediction, :label])
      conn
      |> put_status(:created)
      |> put_resp_header(
        "location",
        ~p"/api/decision_sites/#{decision.decision_site_id}/decisions/#{decision}"
      )
      |> render(:show, decision: decision)
    end
  end

  operation :show,
    summary: "Show decision",
    description: "Show a decision"

  def show(conn, %{"id" => id}) do
    decision = Excisions.get_decision!(id, preloads: [:prediction, :label])
    render(conn, :show, decision: decision)
  end

  operation :update,
    summary: "Update decision",
    description: "Update a decision"

  def update(conn, %{"id" => id, "decision" => decision_params}) do
    decision = Excisions.get_decision!(id)

    with {:ok, %Decision{} = decision} <- Excisions.update_decision(decision, decision_params) do
      decision = Excisions.get_decision!(decision.id, preloads: [:prediction, :label])
      render(conn, :show, decision: decision)
    end
  end

  operation :delete,
    summary: "Delete decision",
    description: "Delete a decision"

  def delete(conn, %{"id" => id}) do
    decision = Excisions.get_decision!(id)

    with {:ok, %Decision{}} <- Excisions.delete_decision(decision) do
      send_resp(conn, :no_content, "")
    end
  end
end
