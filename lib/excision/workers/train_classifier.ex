defmodule Excision.Workers.TrainClassifier do
  use Oban.Worker, queue: :default

  alias Excision.Excisions

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"classifier_id" => classifier_id} = args}) do
    classifier = Excisions.get_classifier!(classifier_id, preloads: [:decision_site])
    Excisions.update_classifier(classifier, %{status: :training})

    {:ok, spec} =
      Bumblebee.load_spec({:hf, "distilbert/distilbert-base-uncased"},
        architecture: :for_sequence_classification
      )

    # TODO: support multi-class when we can customize choices
    spec = Bumblebee.configure(spec, num_labels: 2)
    {:ok, model} = Bumblebee.load_model({:hf, "distilbert/distilbert-base-uncased"}, spec: spec)
    {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, "distilbert/distilbert-base-uncased"})

    # load data as stream
    batch_size = 1
    sequence_length = 64

    tokenizer = Bumblebee.configure(tokenizer, length: sequence_length)

    label_map = %{true => 1, false => 0}
    df = Excisions.list_labelled_decisions_for_site(classifier.decision_site)
      |> Enum.map(fn %Excisions.Decision{
        input: input,
        label: label,
      } -> %{ label: Map.get(label_map, label), text: to_string(input)} end)
      |> Explorer.DataFrame.new()
    train_data = df["text"]
      |> Explorer.Series.to_enum()
      |> Stream.zip(Explorer.Series.to_enum(df["label"]))
      |> Stream.chunk_every(batch_size)
      |> Stream.map(fn batch -> 
        {text, labels} = Enum.unzip(batch)
        tokenized = Bumblebee.apply_tokenizer(tokenizer, text)
        {tokenized, Nx.stack(labels)}
      end)

    # run the fine-time
    %{model: model, params: params} = model
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
    IO.inspect("BEFORE TRAIN")
    trained_model_state = (
      logits_model
        |> Axon.Loop.trainer(loss, optimizer, log: 1)
        |> Axon.Loop.metric(accuracy, "accuracy")
        |> Axon.Loop.checkpoint(event: :epoch_completed, path: checkpoint_path)
        |> Axon.Loop.run(train_data, params, epochs: 3, compiler: EXLA, strict?: false)
    )

    # TODO: train test split and validate on test set
    test_results = logits_model
      |> Axon.Loop.evaluator()
      |> Axon.Loop.metric(accuracy, "accuracy")
      |> Axon.Loop.run(train_data, trained_model_state, epochs: 1, compiler: EXLA)

    IO.inspect("AFTERTRAIN")
    IO.inspect(test_results)
    Excisions.update_classifier(classifier, %{
      status: :trained,
      checkpoint_path: checkpoint_path,
      #accuracy_train: trained_model_state.metrics["accuracy"]
    })
    |> IO.inspect()

    Axon.predict(model, params, "I need oranges")
    |> IO.inspect()
    {model, params} = [checkpoint_path, "checkpoint_2_2.ckpt"] 
      |> Path.join() 
      |> File.read!() 
      |> Axon.Loop.from_state()
    Axon.predict(model, params, "I need oranges")
    |> IO.inspect()


    :ok
  end
end

