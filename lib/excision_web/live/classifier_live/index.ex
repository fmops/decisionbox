defmodule ExcisionWeb.ClassifierLive.Index do
  use ExcisionWeb, :live_view

  alias Excision.Excisions
  alias Excision.Excisions.Classifier

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :classifiers, Excisions.list_classifiers())}
  end

  @impl true
  def handle_params(%{"decision_site_id" => decision_site_id} = params, _url, socket) do
    decision_site = Excisions.get_decision_site!(decision_site_id)

    {:noreply,
     socket
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
    {:noreply, stream_insert(socket, :classifiers, classifier)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    classifier = Excisions.get_classifier!(id)
    {:ok, _} = Excisions.delete_classifier(classifier)

    {:noreply, stream_delete(socket, :classifiers, classifier)}
  end
end
