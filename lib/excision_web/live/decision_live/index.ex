defmodule ExcisionWeb.DecisionLive.Index do
  use ExcisionWeb, :live_view

  alias Excision.Excisions
  alias Excision.Excisions.Decision

  @impl true
  def handle_params(%{"decision_site_id" => decision_site_id} = params, _url, socket) do
    decision_site =
      Excisions.get_decision_site!(decision_site_id, preloads: [:decisions, :choices])

    classifier_id = Map.get(params, "classifier_id")

    classifier =
      if classifier_id do
        Excisions.get_classifier!(classifier_id)
      end

    decisions =
      if classifier_id do
        Excisions.list_decisions_for_classifier(classifier,
          preloads: [:classifier, :label, :prediction]
        )
      else
        Excisions.list_decisions_for_site(decision_site,
          preloads: [:classifier, :label, :prediction]
        )
      end

    {:noreply,
     socket
     |> stream(:decisions, decisions)
     |> assign(:decision_site, decision_site)
     |> assign(:classifier, classifier)
     |> apply_action(socket.assigns.live_action, params)}
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

  @impl true
  def handle_event("label", %{"decision_id" => decision_id, "value" => label_choice_id}, socket) do
    decision = Excisions.get_decision!(decision_id)
    {:ok, decision} = Excisions.label_decision(decision, label_choice_id)

    {:noreply, stream_insert(socket, :decisions, decision)}
  end
end
