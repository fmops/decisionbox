defmodule ExcisionWeb.DecisionSiteLive.Index do
  use ExcisionWeb, :live_view

  alias Excision.Excisions
  alias Excision.Excisions.DecisionSite

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :decision_sites, Excisions.list_decision_sites())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Decision site")
    |> assign(:decision_site, Excisions.get_decision_site!(id, preloads: [:choices]))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Decision site")
    |> assign(:decision_site, %DecisionSite{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Decision sites")
    |> assign(:decision_site, nil)
  end

  @impl true
  def handle_info({ExcisionWeb.DecisionSiteLive.FormComponent, {:saved, decision_site}}, socket) do
    {:noreply, stream_insert(socket, :decision_sites, decision_site)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    decision_site = Excisions.get_decision_site!(id)
    {:ok, _} = Excisions.delete_decision_site(decision_site)

    {:noreply, stream_delete(socket, :decision_sites, decision_site)}
  end
end
