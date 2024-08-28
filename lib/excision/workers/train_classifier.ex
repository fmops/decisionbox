defmodule Excision.Workers.TrainClassifier do
  use Oban.Worker, queue: :default

  alias Excision.Excisions

  def test(id) do
    perform(%Oban.Job{args: %{"classifier_id" => id}})
  end
  

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"classifier_id" => classifier_id}}) do
    classifier = Excisions.get_classifier!(classifier_id, preloads: [:decision_site])
    Excisions.update_classifier(classifier, %{status: :training})

    {:ok, {%{model: model, params: params}, tokenizer}} = load_model_and_tokenizer("distilbert/distilbert-base-uncased")
    train_data = load_data(classifier.decision_site, tokenizer)

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
    loop = (
      logits_model
        |> Axon.Loop.trainer(loss, optimizer, log: 1)
        |> Axon.Loop.metric(accuracy, "accuracy")
        |> Axon.Loop.checkpoint(event: :epoch_completed, path: checkpoint_path)
        |> then(fn loop -> %{loop | output_transform: & &1} end)
        |> Axon.Loop.run(train_data, params, epochs: 3, compiler: EXLA, strict?: false)
    )
    trained_model_state = loop.step_state.model_state
    test_results = logits_model
      |> Axon.Loop.evaluator()
      |> Axon.Loop.metric(accuracy, "accuracy")
      |> Axon.Loop.run(train_data, trained_model_state, epochs: 1, compiler: EXLA)

    Excisions.update_classifier(classifier, %{
      status: :trained,
      checkpoint_path: checkpoint_path,
      train_accuracy: test_results[0]["accuracy"] |> Nx.to_number(),
    })

    :ok


    # example of running inference
    Axon.predict(model, params, Bumblebee.apply_tokenizer(tokenizer, "I need oranges"))
    |> IO.inspect()

    # example of loading a checkpoint from disk
    {:ok, spec} =
      Bumblebee.load_spec({:hf, "distilbert/distilbert-base-uncased"},
        architecture: :for_sequence_classification
      )
    model = Bumblebee.build_model(spec)
    params = [checkpoint_path, "checkpoint_2_2.ckpt"] 
      |> Path.join() 
      |> File.read!() 
      |> Axon.Loop.deserialize_state()
      |> then(& &1.step_state.model_state)
    Axon.predict(model, params, Bumblebee.apply_tokenizer(tokenizer, "I need oranges")) |> IO.inspect()
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

    df = Excisions.list_labelled_decisions_for_site(decision_site)
      |> Enum.map(fn %Excisions.Decision{
        input: input,
        label: label,
      } -> %{ label: Map.get(label_map, label), text: to_string(input)} end)
      |> Explorer.DataFrame.new()

    # TODO: train test split and validate on test set
    train_data = df["text"]
      |> Explorer.Series.to_enum()
      |> Stream.zip(Explorer.Series.to_enum(df["label"]))
      |> Stream.chunk_every(batch_size)
      |> Stream.map(fn batch -> 
        {text, labels} = Enum.unzip(batch)
        tokenized = Bumblebee.apply_tokenizer(tokenizer, text)
        {tokenized, Nx.stack(labels)}
      end)
    train_data
  end
end

