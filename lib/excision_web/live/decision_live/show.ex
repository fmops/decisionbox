defmodule ExcisionWeb.DecisionLive.Show do
  use ExcisionWeb, :live_view

  alias Excision.Excisions

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:decision, Excisions.get_decision!(id))}
  end

  defp page_title(:show), do: "Show Decision"
  defp page_title(:edit), do: "Edit Decision"
end
