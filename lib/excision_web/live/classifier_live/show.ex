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
     |> assign(:classifier, Excisions.get_classifier!(id, preloads: [:decision_site]))}
  end

  @impl true
  def handle_event("promote", %{"classifier_id" => classifier_id}, socket) do
    classifier = Excisions.get_classifier!(classifier_id)
    case Excisions.promote_classifier(classifier) |> IO.inspect() do
      {:ok, _} ->
        classifier = Excisions.get_classifier!(classifier_id, preloads: [:decision_site])
        {:noreply, 
          socket 
          |> put_flash(:info, "Classifier promoted successfully")
          |> assign(:classifier, classifier)
        }

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> put_flash(:error, "Error promoting classifier")}
    end
  end

  defp page_title(:show), do: "Show Classifier"
  defp page_title(:edit), do: "Edit Classifier"
end
