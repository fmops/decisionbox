defmodule Excision.Excisions do
  @moduledoc """
  The Excisions context.
  """

  import Ecto.Query, warn: false
  alias Excision.Repo

  alias Excision.Excisions.DecisionSite

  @doc """
  Returns the list of decision_sites.

  ## Examples

      iex> list_decision_sites()
      [%DecisionSite{}, ...]

  """
  def list_decision_sites do
    Repo.all(DecisionSite)
  end

  @doc """
  Gets a single decision_site.

  Raises `Ecto.NoResultsError` if the Decision site does not exist.

  ## Examples

      iex> get_decision_site!(123)
      %DecisionSite{}

      iex> get_decision_site!(456)
      ** (Ecto.NoResultsError)

  """
  def get_decision_site!(id), do: Repo.get!(DecisionSite, id)

  @doc """
  Creates a decision_site.

  ## Examples

      iex> create_decision_site(%{field: value})
      {:ok, %DecisionSite{}}

      iex> create_decision_site(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_decision_site(attrs \\ %{}) do
    %DecisionSite{}
    |> DecisionSite.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a decision_site.

  ## Examples

      iex> update_decision_site(decision_site, %{field: new_value})
      {:ok, %DecisionSite{}}

      iex> update_decision_site(decision_site, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_decision_site(%DecisionSite{} = decision_site, attrs) do
    decision_site
    |> DecisionSite.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a decision_site.

  ## Examples

      iex> delete_decision_site(decision_site)
      {:ok, %DecisionSite{}}

      iex> delete_decision_site(decision_site)
      {:error, %Ecto.Changeset{}}

  """
  def delete_decision_site(%DecisionSite{} = decision_site) do
    Repo.delete(decision_site)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking decision_site changes.

  ## Examples

      iex> change_decision_site(decision_site)
      %Ecto.Changeset{data: %DecisionSite{}}

  """
  def change_decision_site(%DecisionSite{} = decision_site, attrs \\ %{}) do
    DecisionSite.changeset(decision_site, attrs)
  end
end
