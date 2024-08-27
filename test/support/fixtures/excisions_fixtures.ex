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
        name: "some name"
      })
      |> Excision.Excisions.create_decision_site()

    decision_site
  end

  @doc """
  Generate a decision.
  """
  def decision_fixture(attrs \\ %{}) do
    {:ok, decision} =
      attrs
      |> Enum.into(%{
        input: "some input",
        label: nil,
        prediction: true,
        decision_site_id: Map.get(attrs, :decision_site_id, decision_site_fixture().id)
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
        decision_site_id: Map.get(attrs, :decision_site_id, decision_site_fixture().id)
      })
      |> Excision.Excisions.create_classifier()

    classifier
  end
end
