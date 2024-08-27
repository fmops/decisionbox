defmodule ExcisionWeb.ClassifierLive.Show do
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
     |> assign(:classifier, Excisions.get_classifier!(id))}
  end

  defp page_title(:show), do: "Show Classifier"
  defp page_title(:edit), do: "Edit Classifier"
end
