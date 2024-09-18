defmodule ExcisionWeb.DecisionLive.Index do
  use ExcisionWeb, :live_view

  alias Excision.Excisions
  alias Excision.Excisions.{Decision, DecisionSite}

  require Ecto.Query
  import Ecto.Query, only: [where: 2, where: 3]

  def scope(q, %DecisionSite{id: decision_site_id}),
    do: where(q, decision_site_id: ^decision_site_id)

  def apply_filters(q, opts) do
    Enum.reduce(opts, q, fn
      {:unlabeled, bool}, q -> where(q, [p], is_nil(p.label_id) == ^bool)
      _, q -> q
    end)
  end

  @impl true
  def handle_params(%{"decision_site_id" => decision_site_id} = params, _url, socket) do
    decision_site =
      Excisions.get_decision_site!(decision_site_id, preloads: [:decisions, :choices])

    classifier_id = Map.get(params, "classifier_id")

    classifier =
      if classifier_id do
        Excisions.get_classifier!(classifier_id)
      end

    unlabeled = Map.get(params, "unlabeled")

    {:noreply,
     socket
     |> assign(:decision_site, decision_site)
     |> assign(:classifier, classifier)
     |> assign(:unlabeled, unlabeled)
     |> apply_action(socket.assigns.live_action, params)
     |> then(fn socket ->
       flop =
         params
         |> Map.put("page_size", 10)
         |> Map.put("order_by", ["inserted_at"])
         |> Map.put("order_directions", ["asc"])
         |> Map.put_new("page", 1)
         |> Flop.validate!()

       Decision
       |> scope(decision_site)
       |> apply_filters(
         unless is_nil(unlabeled) do
           %{unlabeled: unlabeled}
         else
           %{}
         end
       )
       |> Flop.run(flop, for: Decision)
       |> case do
         {decisions, meta} ->
           decisions = decisions |> Excision.Repo.preload([:classifier, :prediction, :label])

           socket
           |> assign(:meta, meta)
           |> stream(:decisions, decisions, reset: true)
       end
     end)}
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

  @impl true
  def handle_event("share-clicked", _, socket) do
    {:noreply, socket |> put_flash(:info, "Permalink copied to clipboard")}
  end
end
