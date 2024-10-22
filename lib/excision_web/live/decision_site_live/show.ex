defmodule ExcisionWeb.DecisionSiteLive.Show do
  use ExcisionWeb, :live_view

  alias Excision.Excisions
  import ExcisionWeb.Components, only: [pulsing_dot: 1]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    Phoenix.PubSub.subscribe(Excision.PubSub, "decision_site:#{id}")

    decision_site =
      Excisions.get_decision_site!(id,
        preloads: [:active_classifier, :decisions, :classifiers, :choices]
      )

    accuracy_plot =
      decision_site.classifiers
      |> Enum.map(fn %Excisions.Classifier{inserted_at: date, test_accuracy: test_accuracy} =
                       classifier ->
        accuracy = Excisions.compute_accuracy(classifier)
        [date, if(is_nil(accuracy), do: test_accuracy || 0.0, else: accuracy)]
      end)
      |> Contex.Dataset.new()
      |> Contex.Plot.new(Contex.PointPlot, 600, 400)
      |> Contex.Plot.titles("Classifier performance", "Accuracy of trained classifiers over time")
      |> Contex.Plot.axis_labels("Date", "Accuracy")
      |> Contex.Plot.to_svg()

    baseline_accuracy =
      Excisions.compute_accuracy(
        decision_site.classifiers
        |> Enum.find(
          &(&1.name == Excision.Excisions.Classifier.default_baseline_classifier().name)
        )
      )

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:decision_site, decision_site)
     |> assign(:num_decisions, decision_site.decisions |> Enum.count())
     |> assign(
       :num_unlabeled_decisions,
       decision_site.decisions |> Enum.filter(&is_nil(&1.label_id)) |> Enum.count()
     )
     |> assign(
       :most_recent_decision,
       decision_site.decisions
       |> Enum.map(& &1.inserted_at)
       |> case do
         [] -> "n/a"
         x -> x |> Enum.max(DateTime)
       end
     )
     |> assign(:num_classifiers, decision_site.classifiers |> Enum.count())
     |> assign(:accuracy_plot, accuracy_plot)
     |> assign(:baseline_accuracy, baseline_accuracy)}
  end

  @impl true
  def handle_event("toggle-quickstart", _, socket) do
    if socket.assigns.live_action == :quickstart do
      {:noreply, assign(socket, :live_action, :show)}
    else
      {:noreply, assign(socket, :live_action, :quickstart)}
    end
  end

  @impl true
  def handle_info({:decision_created, _}, socket) do
    {:noreply,
     socket
     |> assign(:num_decisions, socket.assigns.num_decisions + 1)
     |> assign(:num_unlabeled_decisions, socket.assigns.num_unlabeled_decisions + 1)
     |> assign(:most_recent_decision, DateTime.utc_now())}
  end

  @impl true
  def handle_info({:label_created, _}, socket) do
    {:noreply,
     socket |> assign(:num_unlabeled_decisions, socket.assigns.num_unlabeled_decisions - 1)}
  end

  def handle_info(_, socket), do: {:noreply, socket}

  defp page_title(:show), do: "Show Decision site"
  defp page_title(:edit), do: "Edit Decision site"
end
