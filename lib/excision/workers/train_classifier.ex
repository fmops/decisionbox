defmodule Excision.Workers.TrainClassifier do
  require Logger

  use Oban.Worker,
    queue: :default

  alias Excision.Excisions
  alias Excision.Excisions.Classifier.TrainingMetric

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"classifier_id" => classifier_id}, attempt: attempt}) do
    classifier = Excisions.get_classifier!(classifier_id, preloads: [decision_site: [:choices]])

    if attempt > 1 do
      case Excisions.update_classifier_status(classifier, :failed) do
        {:ok, _} -> :ok
        x -> x
      end
    else
      {:ok, _} = Excisions.clear_training_metrics(classifier)
      Excisions.update_classifier_status(classifier, :training)

      train(classifier)
      # emit_fake_metrics(classifier)
    end
  end

  def train(classifier) do
    num_labels = classifier.decision_site.choices |> Enum.count()
    # TODO: allow variable model name
    # model_name = "albert/albert-base-v2"
    model_name = "distilbert/distilbert-base-uncased"

    {:ok, {%{model: model, params: params}, tokenizer}} =
      load_model_and_tokenizer(
        model_name,
        num_labels,
        classifier.training_parameters.sequence_length
      )

    # TODO: if OOM killed, can fix by reducing batch size. Report it.
    {train_data, test_data} =
      load_data(classifier.decision_site, tokenizer, classifier.training_parameters.batch_size)

    # run the fine-time
    logits_model = Axon.nx(model, & &1.logits)

    loss =
      &Axon.Losses.categorical_cross_entropy(&1, &2,
        reduction: :mean,
        from_logits: true,
        sparse: true
      )

    optimizer =
      Polaris.Optimizers.adam(learning_rate: classifier.training_parameters.learning_rate)

    accuracy = &Axon.Metrics.accuracy(&1, &2, from_logits: true, sparse: true)

    checkpoint_path = "checkpoints/#{classifier.id}/"

    # preserve the complete loop struct for grabbing loss traces and metrics
    # https://elixirforum.com/t/how-do-i-get-a-history-of-the-loss-from-axon/56008/7
    loop =
      logits_model
      |> Axon.Loop.trainer(loss, optimizer, log: 1)
      |> Axon.Loop.metric(accuracy, "accuracy")
      |> Axon.Loop.handle_event(
        :iteration_completed,
        fn loop -> log_metrics(loop, classifier) end,
        every: 1
      )
      # TODO: allow checkpointing in training_parameters and warn about sapce usage
      # TODO: resume interrupted training from checkpoints 
      # |> Axon.Loop.checkpoint(event: :epoch_completed, path: checkpoint_path)
      |> then(fn loop -> %{loop | output_transform: & &1} end)
      |> Axon.Loop.run(train_data, params,
        epochs: classifier.training_parameters.epochs,
        strict?: false
      )

    trained_model_state = loop.step_state.model_state

    if !File.exists?(checkpoint_path) do
      File.mkdir!(checkpoint_path)
    end

    Nx.serialize(trained_model_state)
    |> then(&File.write!(Path.join([checkpoint_path, "parameters.nx"]), &1))

    train_accuracy = loop.metrics[0]["accuracy"] |> Nx.to_number()

    # TODO: eval once per epoch during training
    test_results =
      logits_model
      |> Axon.Loop.evaluator()
      |> Axon.Loop.metric(accuracy, "accuracy")
      |> Axon.Loop.run(test_data, trained_model_state)

    test_accuracy = test_results[0]["accuracy"] |> Nx.to_number()

    Excisions.update_classifier(classifier, %{
      checkpoint_path: checkpoint_path,
      train_accuracy: train_accuracy,
      test_accuracy: test_accuracy
    })

    Excisions.update_classifier_status(classifier, :trained)

    :ok
  end

  defp load_model_and_tokenizer(model_name, num_labels, sequence_length) do
    {:ok, spec} =
      Bumblebee.load_spec({:hf, model_name},
        architecture: :for_sequence_classification
      )

    spec = Bumblebee.configure(spec, num_labels: num_labels)

    {:ok, model} = Bumblebee.load_model({:hf, model_name}, spec: spec)
    {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, model_name})

    tokenizer = Bumblebee.configure(tokenizer, length: sequence_length)

    {:ok, {model, tokenizer}}
  end

  defp load_data(decision_site, tokenizer, batch_size) do
    label_map = Excisions.build_label_map(decision_site)

    df =
      Excisions.list_labelled_decisions_for_site(decision_site)
      |> Enum.map(fn %Excisions.Decision{
                       input: input,
                       label: label
                     } ->
        %{label: Map.get(label_map, label.name), text: to_string(input)}
      end)
      |> Explorer.DataFrame.new()

    {num_examples, _} = Explorer.DataFrame.shape(df)
    num_train = (num_examples * frac_train()) |> round() |> Kernel.max(1)

    train_data =
      df
      |> Explorer.DataFrame.slice(0..(num_train - 1))
      |> make_example_stream(batch_size, tokenizer)

    test_data =
      df
      |> Explorer.DataFrame.slice(num_train..num_examples)
      |> make_example_stream(batch_size, tokenizer)

    {train_data, test_data}
  end

  defp make_example_stream(df, batch_size, tokenizer) do
    df["text"]
    |> Explorer.Series.to_enum()
    |> Stream.zip(Explorer.Series.to_enum(df["label"]))
    |> Stream.chunk_every(batch_size)
    |> Stream.map(fn batch ->
      {text, labels} = Enum.unzip(batch)
      tokenized = Bumblebee.apply_tokenizer(tokenizer, text)
      {tokenized, Nx.stack(labels)}
    end)
  end

  defp log_metrics(
         %Axon.Loop.State{
           metrics: %{
             "accuracy" => accuracy,
             "loss" => loss
           },
           epoch: epoch,
           iteration: iteration
         } = state,
         classifier
       ) do
    training_metrics = %TrainingMetric{
      timestamp: DateTime.utc_now(),
      accuracy: accuracy |> Nx.to_number(),
      loss: loss |> Nx.to_number(),
      epoch: epoch,
      iteration: iteration
    }

    Excisions.append_training_metrics(classifier, training_metrics)

    {:continue, state}
  end

  @doc """
  Fake training loop to emit metrics. Useful for testing the UI.
  """
  def emit_fake_metrics(classifier) do
    for i <- 1..10 do
      Process.sleep(1000)
      Logger.debug("Emitting: #{i}")

      training_metrics = %TrainingMetric{
        timestamp: DateTime.utc_now(),
        accuracy: i,
        loss: 0.1 * i,
        epoch: 1,
        iteration: i
      }

      Excisions.append_training_metrics(classifier, training_metrics)
    end

    :ok
  end

  # TODO: move to training_parameters
  def frac_train, do: 0.8
end
