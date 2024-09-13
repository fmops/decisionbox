defmodule ExcisionWeb.ClassifierLive.Index do
  use ExcisionWeb, :live_view

  alias Excision.Excisions
  alias Excision.Excisions.Classifier
  import Excision.Workers.TrainClassifier, only: [frac_train: 0]

  @impl true
  def handle_params(%{"decision_site_id" => decision_site_id} = params, _url, socket) do
    decision_site = Excisions.get_decision_site!(decision_site_id, preloads: [:decisions])

    {:noreply,
     socket
     |> stream(:classifiers, Excisions.list_classifiers_for_decision_site(decision_site))
     |> assign(:decision_site, decision_site)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Classifier")
    |> assign(:classifier, Excisions.get_classifier!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Classifier")
    |> assign(:classifier, %Classifier{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Classifiers")
    |> assign(:classifier, nil)
  end

  @impl true
  def handle_info({ExcisionWeb.ClassifierLive.FormComponent, {:saved, classifier}}, socket) do
    classifier = Excisions.get_classifier!(classifier.id)

    {:noreply,
     socket
     |> stream_insert(:classifiers, classifier)
     |> assign(:classifier, classifier)
     |> assign(:live_action, :confidence_dialog)}

    {:noreply, stream_insert(socket, :classifiers, classifier)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    classifier = Excisions.get_classifier!(id)
    {:ok, _} = Excisions.delete_classifier(classifier)

    {:noreply, stream_delete(socket, :classifiers, classifier)}
  end

  @impl true
  def handle_event("promote", %{"id" => id}, socket) do
    classifier = Excisions.get_classifier!(id)

    case Excisions.promote_classifier(classifier) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Classifier promoted successfully")}

      {:error, %Ecto.Changeset{}} ->
        {:noreply, socket |> put_flash(:error, "Error promoting classifier")}
    end
  end

  @impl true
  def handle_event("train", %{"id" => id}, socket) do
    classifier = Excisions.get_classifier!(id)

    case Excisions.train_classifier(classifier) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Training job submitted successfully")}

      {:error, %Ecto.Changeset{}} ->
        {:noreply, socket |> put_flash(:error, "Error submitting training job")}
    end
  end
end
