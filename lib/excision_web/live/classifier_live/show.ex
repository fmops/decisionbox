defmodule ExcisionWeb.ClassifierLive.Show do
  use ExcisionWeb, :live_view

  alias Excision.Excisions

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    classifier = Excisions.get_classifier!(id, preloads: [:decision_site, :decisions])

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:classifier, classifier)
     |> assign(:num_decisions, classifier.decisions |> Enum.count())}
  end

  @impl true
  def handle_event("promote", _params, %{assigns: %{classifier: classifier}} = socket) do
    case Excisions.promote_classifier(classifier) |> IO.inspect() do
      {:ok, _} ->
        classifier = Excisions.get_classifier!(classifier.id, preloads: [:decision_site])

        {:noreply,
         socket
         |> put_flash(:info, "Classifier promoted successfully")
         |> assign(:classifier, classifier)}

      {:error, %Ecto.Changeset{}} ->
        {:noreply, socket |> put_flash(:error, "Error promoting classifier")}
    end
  end

  @impl true
  def handle_event("train", _params, %{assigns: %{classifier: classifier}} = socket) do
    case Excisions.train_classifier(classifier) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Training job submitted successfully")}

      {:error, %Ecto.Changeset{}} ->
        {:noreply, socket |> put_flash(:error, "Error submitting training job")}
    end
  end

  defp page_title(:show), do: "Show Classifier"
  defp page_title(:edit), do: "Edit Classifier"
end
