defmodule ExcisionWeb.DecisionSiteLive.Show do
  use ExcisionWeb, :live_view

  alias Excision.Excisions

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    Phoenix.PubSub.subscribe(Excision.PubSub, "decision_site:#{id}")

    decision_site =
      Excisions.get_decision_site!(id, preloads: [:active_classifier, :decisions, :classifiers])

    accuracy_plot = decision_site.classifiers
    |> Enum.map(fn %Excisions.Classifier{inserted_at: date, test_accuracy: test_accuracy} = classifier -> 
      accuracy = Excisions.compute_accuracy(classifier)
      [date, (if is_nil(accuracy), do: test_accuracy, else: accuracy)]
    end)
      |> Contex.Dataset.new()
      |> Contex.Plot.new(Contex.PointPlot, 600, 400)
      |> Contex.Plot.titles("Classifier performance", "Accuracy of trained classifiers over time")
      |> Contex.Plot.axis_labels("Date", "Accuracy")
      |> Contex.Plot.to_svg()

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:decision_site, decision_site)
     |> assign(:num_decisions, decision_site.decisions |> Enum.count())
     |> assign(
       :num_labelled_decisions,
       decision_site.decisions |> Enum.filter(&(not is_nil(&1.label))) |> Enum.count()
     )
     |> assign(:num_classifiers, decision_site.classifiers |> Enum.count())
     |> assign(:accuracy_plot, accuracy_plot)
    }
  end

  @impl true
  def handle_info({:decision_created, _}, socket) do
    {:noreply, socket |> assign(:num_decisions, socket.assigns.num_decisions + 1)}
  end

  @impl true
  def handle_info({:label_created, _} = x, socket) do
    IO.inspect(x)
    {:noreply, socket |> assign(:num_labelled_decisions, socket.assigns.num_labelled_decisions + 1)}
  end
  

  defp page_title(:show), do: "Show Decision site"
  defp page_title(:edit), do: "Edit Decision site"
end
