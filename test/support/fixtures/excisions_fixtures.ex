defmodule Excision.ExcisionsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Excision.Excisions` context.
  """

  @doc """
  Generate a decision_site.
  """
  def decision_site_fixture(attrs \\ %{}) do
    {:ok, decision_site} =
      attrs
      |> Enum.into(%{
        name: "some name",
        choices: [
          %{
            name: "some name"
          }
        ]
      })
      |> Excision.Excisions.create_decision_site()

    decision_site
  end

  @doc """
  Generate a decision.
  """
  def decision_fixture(attrs \\ %{}) do
    decision_site = Excision.Excisions.get_decision_site!(Map.get(attrs, :decision_site_id, decision_site_fixture().id), preloads: [:choices])
    {:ok, decision} =
      attrs
      |> Enum.into(%{
        input: "some input",
        label: nil,
        prediction_id: decision_site.choices |> hd() |> then(& &1.id),
        decision_site_id: decision_site.id
      })
      |> Excision.Excisions.create_decision()

    decision
  end

  @doc """
  Generate a classifier.
  """
  def classifier_fixture(attrs \\ %{}) do
    {:ok, classifier} =
      attrs
      |> Enum.into(%{
        name: "some name",
        status: "waiting",
        training_parameters: %{
          learning_rate: 0.1,
          batch_size: 32,
          sequence_length: 100,
          epochs: 10
        },
        decision_site_id: Map.get(attrs, :decision_site_id, decision_site_fixture().id)
      })
      |> Excision.Excisions.create_classifier()

    classifier
  end

  @doc """
  Generate a choice.
  """
  def choice_fixture(attrs \\ %{}) do
    {:ok, choice} =
      attrs
      |> Enum.into(%{
        name: "some name",
        decision_site_id: Map.get(attrs, :decision_site_id, decision_site_fixture().id)
      })
      |> Excision.Excisions.create_choice()

    choice
  end
end
