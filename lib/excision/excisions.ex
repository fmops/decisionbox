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
  def list_decision_sites(opts \\ []) do
    preloads = Keyword.get(opts, :preloads, [])

    DecisionSite
    |> Repo.all()
    |> Repo.preload(preloads)
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
  def get_decision_site!(id, opts \\ []) do
    preloads = Keyword.get(opts, :preloads, [])

    DecisionSite
    |> Repo.get!(id)
    |> Repo.preload(preloads)
  end

  @doc """
  Creates a decision_site.

  ## Examples

      iex> create_decision_site(%{field: value})
      {:ok, %DecisionSite{}}

      iex> create_decision_site(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_decision_site(attrs \\ %{}) do
    # create the default classifier
    {:ok, classifier} =
      Excision.Excisions.Classifier.default_baseline_classifier()
      |> Excision.Excisions.Classifier.changeset(%{})
      |> Repo.insert()

    %DecisionSite{}
    |> DecisionSite.changeset(attrs)
    |> Ecto.Changeset.apply_changes()
    |> DecisionSite.changeset(%{active_classifier_id: classifier.id})
    |> Ecto.Changeset.put_assoc(:classifiers, [classifier])
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

  def preload_decision_site_classifiers(%DecisionSite{} = decision_site) do
    Repo.preload(decision_site, :classifiers)
  end

  alias Excision.Excisions.Decision

  @doc """
  Returns the list of decisions.

  ## Examples

      iex> list_decisions()
      [%Decision{}, ...]

  """
  def list_decisions do
    Repo.all(Decision)
  end

  @doc """
  Returns the list of decisions for a single site

  ## Examples

      iex> list_decisions_for_site(decision_site)
      [%Decision{}, ...]

  """
  def list_decisions_for_site(%DecisionSite{} = decision_site) do
    from(d in Decision, where: d.decision_site_id == ^decision_site.id)
    |> Repo.all()
  end

  @doc """
  Returns the list of labelled decisions for a single site

  ## Examples

      iex> list_labelled_decisions_for_site(decision_site)
      [%Decision{}, ...]

  """
  def list_labelled_decisions_for_site(%DecisionSite{} = decision_site) do
    from(d in Decision)
    |> where([d], d.decision_site_id == ^decision_site.id)
    |> where([d], not is_nil(d.label))
    |> Repo.all()
  end

  @doc """
  Gets a single decision.

  Raises `Ecto.NoResultsError` if the Decision does not exist.

  ## Examples

      iex> get_decision!(123)
      %Decision{}

      iex> get_decision!(456)
      ** (Ecto.NoResultsError)

  """
  def get_decision!(id), do: Repo.get!(Decision, id)

  @doc """
  Creates a decision.

  ## Examples

      iex> create_decision(%{field: value})
      {:ok, %Decision{}}

      iex> create_decision(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_decision(attrs \\ %{}) do
    %Decision{}
    |> Decision.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a decision.

  ## Examples

      iex> update_decision(decision, %{field: new_value})
      {:ok, %Decision{}}

      iex> update_decision(decision, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_decision(%Decision{} = decision, attrs) do
    decision
    |> Decision.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a decision.

  ## Examples

      iex> delete_decision(decision)
      {:ok, %Decision{}}

      iex> delete_decision(decision)
      {:error, %Ecto.Changeset{}}

  """
  def delete_decision(%Decision{} = decision) do
    Repo.delete(decision)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking decision changes.

  ## Examples

      iex> change_decision(decision)
      %Ecto.Changeset{data: %Decision{}}

  """
  def change_decision(%Decision{} = decision, attrs \\ %{}) do
    Decision.changeset(decision, attrs)
  end

  alias Excision.Excisions.Classifier

  @doc """
  Returns the list of classifiers.

  ## Examples

      iex> list_classifiers()
      [%Classifier{}, ...]

  """
  def list_classifiers do
    Repo.all(Classifier)
  end

  @doc """
  Gets a single classifier.

  Raises `Ecto.NoResultsError` if the Classifier does not exist.

  ## Examples

      iex> get_classifier!(123)
      %Classifier{}

      iex> get_classifier!(456)
      ** (Ecto.NoResultsError)

  """
  def get_classifier!(id, opts \\ []) do
    preloads = Keyword.get(opts, :preloads, [])

    Classifier
      |> Repo.get!(id)
      |> Repo.preload(preloads)
  end

  @doc """
  Creates a classifier.

  ## Examples

      iex> create_classifier(%{field: value})
      {:ok, %Classifier{}}

      iex> create_classifier(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_classifier(attrs \\ %{}) do
    %Classifier{}
      |> Classifier.changeset(attrs)
      |> Repo.insert()
    |> case do
      {:ok, classifier} ->
        %{ classifier_id: classifier.id }
        |> Excision.Workers.TrainClassifier.new()
        |> Oban.insert()

        {:ok, classifier}
      x -> x
    end
  end

  @doc """
  Updates a classifier.

  ## Examples

      iex> update_classifier(classifier, %{field: new_value})
      {:ok, %Classifier{}}

      iex> update_classifier(classifier, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_classifier(%Classifier{} = classifier, attrs) do
    classifier
    |> Classifier.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a classifier.

  ## Examples

      iex> delete_classifier(classifier)
      {:ok, %Classifier{}}

      iex> delete_classifier(classifier)
      {:error, %Ecto.Changeset{}}

  """
  def delete_classifier(%Classifier{} = classifier) do
    Repo.delete(classifier)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking classifier changes.

  ## Examples

      iex> change_classifier(classifier)
      %Ecto.Changeset{data: %Classifier{}}

  """
  def change_classifier(%Classifier{} = classifier, attrs \\ %{}) do
    Classifier.changeset(classifier, attrs)
  end
end
