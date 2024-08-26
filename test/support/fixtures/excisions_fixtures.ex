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
end
