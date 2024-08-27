defmodule ExcisionWeb.DecisionLive.Index do
  use ExcisionWeb, :live_view

  alias Excision.Excisions
  alias Excision.Excisions.Decision

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :decisions, Excisions.list_decisions())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Decision")
    |> assign(:decision, Excisions.get_decision!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Decision")
    |> assign(:decision, %Decision{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Decisions")
    |> assign(:decision, nil)
  end

  @impl true
  def handle_info({ExcisionWeb.DecisionLive.FormComponent, {:saved, decision}}, socket) do
    {:noreply, stream_insert(socket, :decisions, decision)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    decision = Excisions.get_decision!(id)
    {:ok, _} = Excisions.delete_decision(decision)

    {:noreply, stream_delete(socket, :decisions, decision)}
  end
end
