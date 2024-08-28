defmodule Excision.Workers.TrainClassifier do
  use Oban.Worker,
    queue: :default,
    unique: [period: 30]

  alias Excision.Excisions

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"classifier_id" => classifier_id}, attempt: attempt}) do
    classifier = Excisions.get_classifier!(classifier_id, preloads: [:decision_site])

    IO.inspect("HI MOM")

    if attempt > 1 do
      case Excisions.update_classifier(classifier, %{status: :failed}) do
        {:ok, _} -> :ok
        x -> x
      end
    else
      train2(classifier)
    end
  end

  def train2(classifier) do
    for i <- 1..10 do
      Process.sleep(1000)
      IO.inspect("Emitting: #{i}")
      Phoenix.PubSub.broadcast(
        Excision.PubSub, 
        "classifier:#{classifier.id}", 
        {:training_metrics_emitted, %{
          timestamp: DateTime.utc_now(),
          accuracy: i,
          loss: 0.1 * i
        }}
      )
    end
    :ok
  end

  def train(classifier) do
    Excisions.update_classifier(classifier, %{status: :training})

    {:ok, {%{model: model, params: params}, tokenizer}} =
      load_model_and_tokenizer("distilbert/distilbert-base-uncased")

    {train_data, test_data} = load_data(classifier.decision_site, tokenizer)

    # run the fine-time
    logits_model = Axon.nx(model, & &1.logits)

    loss =
      &Axon.Losses.categorical_cross_entropy(&1, &2,
        reduction: :mean,
        from_logits: true,
        sparse: true
      )

    # TODO: configurable and report hyperparameters like lr, batch size, seq length
    optimizer = Polaris.Optimizers.adam(learning_rate: 5.0e-5)
    accuracy = &Axon.Metrics.accuracy(&1, &2, from_logits: true, sparse: true)

    # TODO: callback to report progress back to postgres
    # TODO: configurable number of epochs
    checkpoint_path = "checkpoints/#{classifier.id}/"

    # preserve the complete loop struct for grabbing loss traces and metrics
    # https://elixirforum.com/t/how-do-i-get-a-history-of-the-loss-from-axon/56008/7
    loop =
      logits_model
      |> Axon.Loop.trainer(loss, optimizer, log: 1)
      |> Axon.Loop.metric(accuracy, "accuracy")
      |> Axon.Loop.checkpoint(event: :epoch_completed, path: checkpoint_path)
      |> then(fn loop -> %{loop | output_transform: & &1} end)
      |> Axon.Loop.run(train_data, params, epochs: 3, strict?: false)

    trained_model_state = loop.step_state.model_state
    train_accuracy = loop.metrics[0]["accuracy"] |> Nx.to_number()

    test_results =
      logits_model
      |> Axon.Loop.evaluator()
      |> Axon.Loop.metric(accuracy, "accuracy")
      |> Axon.Loop.run(test_data, trained_model_state)

    test_accuracy = test_results[0]["accuracy"] |> Nx.to_number()

    Excisions.update_classifier(classifier, %{
      status: :trained,
      checkpoint_path: checkpoint_path,
      train_accuracy: train_accuracy,
      test_accuracy: test_accuracy
    })

    :ok
  end

  defp load_model_and_tokenizer(model_name) do
    {:ok, spec} =
      Bumblebee.load_spec({:hf, model_name},
        architecture: :for_sequence_classification
      )

    # TODO: support multi-class when we can customize choices
    spec = Bumblebee.configure(spec, num_labels: 2)

    {:ok, model} = Bumblebee.load_model({:hf, model_name}, spec: spec)
    {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, model_name})

    sequence_length = 64
    tokenizer = Bumblebee.configure(tokenizer, length: sequence_length)

    {:ok, {model, tokenizer}}
  end

  defp load_data(decision_site, tokenizer) do
    batch_size = 64
    label_map = %{true => 1, false => 0}

    df =
      Excisions.list_labelled_decisions_for_site(decision_site)
      |> Enum.map(fn %Excisions.Decision{
                       input: input,
                       label: label
                     } ->
        %{label: Map.get(label_map, label), text: to_string(input)}
      end)
      |> Explorer.DataFrame.new()

    {num_examples, _} = Explorer.DataFrame.shape(df)
    num_train = (num_examples * 0.8) |> round() |> Kernel.max(1)

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
end
