defmodule Excision.Workers.TrainClassifier do
  use Oban.Worker, queue: :default

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"classifier_id" => classifier_id} = args}) do
    classifier = Excision.Excisions.get_classifier!(classifier_id)
    Excision.Excisions.update_classifier(classifier, %{status: :training})

    IO.inspect("TODO: finetune distilbert-base-uncased against the dataset")

    :ok
  end
end

