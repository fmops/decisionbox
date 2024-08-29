defmodule Excision.OntologiesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Excision.Ontologies` context.
  """

  import Excision.ExcisionsFixtures

  @doc """
  Generate a label.
  """
  def label_fixture(attrs \\ %{}) do
    {:ok, label} =
      attrs
      |> Enum.into(%{
        name: "some name",
        decision_site_id: Map.get(attrs, :decision_site_id, decision_site_fixture().id)
      })
      |> Excision.Ontologies.create_label()

    label
  end
end
