defmodule ExcisionWeb.ClassifierLive.Show do
  use ExcisionWeb, :live_view

  alias Excision.Excisions
  import Excision.Excisions, only: [is_default_classifier?: 1]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:metrics, [])
     |> assign(:progress, nil)}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    Phoenix.PubSub.subscribe(Excision.PubSub, "classifier:#{id}")

    classifier = Excisions.get_classifier!(id, preloads: [:decision_site, :decisions])
    accuracy = Excisions.compute_accuracy(classifier)

    num_labels_for_site =
      Excisions.list_decisions_for_site(classifier.decision_site)
      |> Enum.filter(&(not is_nil(&1.label)))
      |> Enum.count()

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:classifier, classifier)
     |> assign(
       :num_labels_for_site,
       num_labels_for_site
     )
     |> assign(:num_decisions, classifier.decisions |> Enum.count())
     |> assign(
       :num_labelled_decisions,
       classifier.decisions |> Enum.filter(&(not is_nil(&1.label))) |> Enum.count()
     )
     |> assign(:accuracy, accuracy)
     |> assign(:metrics, classifier.training_metrics)
     |> assign(
       :progress,
       compute_progress_from_metrics(
         classifier.training_metrics,
         classifier.training_parameters,
         num_labels_for_site
       )
     )}
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
         |> put_flash(:info, "Training job submitted successfully")
         |> assign(:progress, %{
           iter: 0,
           max_iters: 10,
           epoch: 0,
           max_epochs: classifier.training_parameters.epochs,
           eta: nil
         })}

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
    updated_metrics = [metrics | socket.assigns.metrics]

    progress =
      compute_progress_from_metrics(
        updated_metrics,
        socket.assigns.classifier.training_parameters,
        socket.assigns.num_labels_for_site
      )

    {:noreply,
     socket
     |> assign(:metrics, updated_metrics)
     |> assign(:progress, progress)}
  end

  @impl true
  def handle_info({:training_metrics_cleared, _}, socket) do
    {:noreply,
     socket
     |> assign(:metrics, [])}
  end

  def handle_info(_, socket), do: {:noreply, socket}

  defp make_loss_plot(metrics) do
    metrics
    |> Enum.map(fn %{timestamp: date, loss: loss} ->
      [date, loss]
    end)
    |> Contex.Dataset.new()
    |> Contex.Plot.new(Contex.LinePlot, 600, 400)
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
    |> Contex.Plot.new(Contex.LinePlot, 600, 400)
    |> Contex.Plot.titles("Training accuracy trace", "")
    |> Contex.Plot.axis_labels("Timestamp", "Accuracy")
    |> Contex.Plot.to_svg()
  end

  defp compute_progress_from_metrics([], _, _), do: nil

  defp compute_progress_from_metrics(
         metrics,
         %Excisions.Classifier.TrainingParameters{
           batch_size: batch_size,
           epochs: max_epochs
         },
         num_labels
       ) do
    most_recent_metrics = Enum.at(metrics, 0)

    n_train =
      num_labels
      |> then(&(&1 * Excision.Workers.TrainClassifier.frac_train()))
      |> ceil()

    iter_per_epoch = ceil(n_train / batch_size)
    iter = most_recent_metrics.epoch * iter_per_epoch + most_recent_metrics.iteration
    max_iters = iter_per_epoch * max_epochs

    seconds_per_iter = estimate_time_per_iter(metrics)

    %{
      iter: iter,
      max_iters: max_iters,
      epoch: most_recent_metrics.epoch,
      max_epochs: max_epochs,
      eta:
        case seconds_per_iter do
          nil ->
            "n/a"

          _ ->
            Timex.Duration.from_seconds(seconds_per_iter * (max_iters - iter))
            |> Timex.format_duration(:humanized)
        end
    }
  end

  defp estimate_time_per_iter(metrics) do
    case metrics do
      [] ->
        nil

      [_] ->
        nil

      xs ->
        time_per_iter =
          xs
          |> Enum.chunk_every(2, 1, :discard)
          |> Enum.map(fn [a, b] -> DateTime.diff(a.timestamp, b.timestamp, :second) end)

        mean_time_per_iter = Enum.reduce(time_per_iter, 0, &(&1 + &2)) / Enum.count(time_per_iter)
        mean_time_per_iter
    end
  end

  defp page_title(:show), do: "Show Classifier"
  defp page_title(:edit), do: "Edit Classifier"
end
