defmodule ExcisionWeb.DecisionController do
  use ExcisionWeb, :controller

  alias Excision.Excisions
  alias Excision.Excisions.Decision

  action_fallback ExcisionWeb.FallbackController

  def index(conn, _params) do
    decisions = Excisions.list_decisions()
    render(conn, :index, decisions: decisions)
  end

  def create(conn, %{"decision" => decision_params}) do
    with {:ok, %Decision{} = decision} <- Excisions.create_decision(decision_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/decision_sites/#{decision.decision_site_id}/decisions/#{decision}")
      |> render(:show, decision: decision)
    end
  end

  def show(conn, %{"id" => id}) do
    decision = Excisions.get_decision!(id)
    render(conn, :show, decision: decision)
  end

  def update(conn, %{"id" => id, "decision" => decision_params}) do
    decision = Excisions.get_decision!(id)

    with {:ok, %Decision{} = decision} <- Excisions.update_decision(decision, decision_params) do
      render(conn, :show, decision: decision)
    end
  end

  def delete(conn, %{"id" => id}) do
    decision = Excisions.get_decision!(id)

    with {:ok, %Decision{}} <- Excisions.delete_decision(decision) do
      send_resp(conn, :no_content, "")
    end
  end
end
