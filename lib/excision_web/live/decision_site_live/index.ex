defmodule ExcisionWeb.DecisionSiteLive.Index do
  use ExcisionWeb, :live_view

  alias Excision.Excisions
  alias Excision.Excisions.DecisionSite
  import ExcisionWeb.Components, only: [pulsing_dot: 1]

  @impl true
  def mount(_params, _session, socket) do
    decision_sites =
      Excisions.list_decision_sites(preloads: [:decisions, :classifiers])

    decision_sites
    |> Enum.map(fn decision_site ->
      Phoenix.PubSub.subscribe(Excision.PubSub, "decision_site:#{decision_site.id}")
    end)

    num_decisions =
      decision_sites
      |> Enum.map(fn decision_site ->
        {decision_site.id, decision_site.decisions |> Enum.count()}
      end)
      |> Enum.into(%{})

    num_unlabeled_decisions =
      decision_sites
      |> Enum.map(fn decision_site ->
        {decision_site.id,
         decision_site.decisions
         |> Enum.filter(&is_nil(&1.label_id))
         |> Enum.count()}
      end)
      |> Enum.into(%{})

    num_classifiers =
      decision_sites
      |> Enum.map(fn decision_site ->
        {decision_site.id, decision_site.classifiers |> Enum.count()}
      end)
      |> Enum.into(%{})

    {:ok,
     socket
     |> stream(:decision_sites, decision_sites)
     |> assign(:num_decisions, num_decisions)
     |> assign(:num_unlabeled_decisions, num_unlabeled_decisions)
     |> assign(:num_classifiers, num_classifiers)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    decision_site = Excisions.get_decision_site!(id, preloads: [:decisions, :choices])

    socket
    |> assign(:page_title, "Edit decision site: #{decision_site.name}")
    |> assign(:decision_site, decision_site)
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
    decision_site =
      Excisions.get_decision_site!(decision_site.id, preloads: [:decisions, :choices])

    {:noreply,
     socket
     |> stream_insert(
       :decision_sites,
       decision_site
     )
     |> assign(:decision_site, decision_site)
     |> assign(:live_action, :confidence_dialog)}
  end

  @impl true
  def handle_info({:decision_created, %{decision: decision}}, socket) do
    {:noreply,
     socket
     |> assign(
       :num_decisions,
       socket.assigns.num_decisions
       |> Map.update!(decision.decision_site_id, &(&1 + 1))
     )
     |> assign(
       :num_unlabeled_decisions,
       socket.assigns.num_decisions
       |> Map.update!(decision.decision_site_id, &(&1 + 1))
     )}
  end

  @impl true
  def handle_info({:label_created, %{decision: decision}}, socket) do
    {:noreply,
     socket
     |> assign(
       :num_unlabeled_decisions,
       socket.assigns.num_labelled_decisions
       |> Map.update!(decision.decision_site_id, &(&1 - 1))
     )}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    decision_site = Excisions.get_decision_site!(id)
    {:ok, _} = Excisions.delete_decision_site(decision_site)

    {:noreply, stream_delete(socket, :decision_sites, decision_site)}
  end
end
