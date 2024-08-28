defmodule ExcisionWeb.ClassifierLive.Show do
  use ExcisionWeb, :live_view

  alias Excision.Excisions
  import Excision.Excisions, only: [is_default_classifier?: 1]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:metrics, [])
     |> assign(:loss_plot, nil)}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    Phoenix.PubSub.subscribe(Excision.PubSub, "classifier:#{id}")

    classifier = Excisions.get_classifier!(id, preloads: [:decision_site, :decisions])
    accuracy = Excisions.compute_accuracy(classifier)

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:classifier, classifier)
     |> assign(:num_decisions, classifier.decisions |> Enum.count())
     |> assign(
       :num_labelled_decisions,
       classifier.decisions |> Enum.filter(&(not is_nil(&1.label))) |> Enum.count()
     )
     |> assign(:accuracy, accuracy)}
  end

  @impl true
  def handle_event("promote", _params, %{assigns: %{classifier: classifier}} = socket) do
    case Excisions.promote_classifier(classifier) do
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

  @impl true
  def handle_info({:status_updated, status}, socket) do
    {:noreply,
     socket
     |> assign(:classifier, socket.assigns.classifier |> Map.put(:status, status))}
  end

  @impl true
  def handle_info({:training_metrics_emitted, metrics}, socket) do
    new_metrics = [metrics | socket.assigns.metrics]

    {:noreply,
     socket
     |> assign(:metrics, new_metrics)
     |> assign(:loss_plot, make_loss_plot(new_metrics))
     |> assign(:accuracy_plot, make_accuracy_plot(new_metrics))}
  end

  defp make_loss_plot(metrics) do
    metrics
    |> Enum.map(fn %{timestamp: date, loss: loss} ->
      [date, loss]
    end)
    |> Contex.Dataset.new()
    |> Contex.Plot.new(Contex.PointPlot, 600, 400)
    |> Contex.Plot.titles("Training loss trace", "")
    |> Contex.Plot.axis_labels("Timestamp", "Loss")
    |> Contex.Plot.to_svg()
  end

  defp make_accuracy_plot(metrics) do
    metrics
    |> Enum.map(fn %{timestamp: date, accuracy: accuracy} ->
      [date, accuracy]
    end)
    |> Contex.Dataset.new()
    |> Contex.Plot.new(Contex.PointPlot, 600, 400)
    |> Contex.Plot.titles("Training accuracy trace", "")
    |> Contex.Plot.axis_labels("Timestamp", "Accuracy")
    |> Contex.Plot.to_svg()
  end

  defp page_title(:show), do: "Show Classifier"
  defp page_title(:edit), do: "Edit Classifier"
end
