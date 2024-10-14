defmodule Excision.Seed do
  alias Excision.Excisions

  def seed do
    %{review: texts, rating: labels} = Scidata.YelpFullReviews.download()

    {:ok, decision_site} =
      Excisions.create_decision_site(%{
        name: "yelp reviews",
        choices:
          labels
          |> Enum.uniq()
          |> Enum.map(&to_string/1)
          |> Enum.sort()
          |> Enum.with_index()
          |> Enum.map(fn {val, idx} -> {idx, %{name: val}} end)
          |> Enum.into(%{})
      })

    for {text, label} <- Enum.zip(texts, labels) |> Enum.take(100) do
      Excisions.create_decision(%{
        decision_site_id: decision_site.id,
        classifier_id: decision_site.classifiers |> Enum.at(0) |> then(& &1.id),
        input: text,
        prediction_id: decision_site.choices |> Enum.random() |> then(& &1.id),
        label_id:
          decision_site.choices |> Enum.find(&(&1.name == to_string(label))) |> then(& &1.id)
      })
    end

    {:ok, _} =
      Excisions.create_classifier(%{
        decision_site_id: decision_site.id,
        name: "seeded classifier",
        base_model_name: Excision.Excisions.Classifier.default_model_name(),
        training_parameters: %{
          learning_rate: 5.0e-3,
          batch_size: 64,
          sequence_length: 64,
          epochs: 3
        }
      })
  end
end
