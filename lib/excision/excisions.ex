defmodule Excision.Excisions do
  @moduledoc """
  The Excisions context.
  """

  import Ecto.Query, warn: false
  alias Excision.Repo

  alias Excision.Excisions.{Classifier, Decision, DecisionSite, Choice}

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
      Excision.Excisions.Classifier.default_passthrough_classifier()
      |> Excision.Excisions.Classifier.changeset(%{})
      |> Repo.insert()

    %DecisionSite{}
    |> DecisionSite.changeset(attrs)
    |> Ecto.Changeset.apply_changes()
    |> DecisionSite.changeset(%{promoted_classifier_id: classifier.id})
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
  def list_decisions_for_site(%DecisionSite{} = decision_site, opts \\ []) do
    preloads = Keyword.get(opts, :preloads, [])

    from(d in Decision, where: d.decision_site_id == ^decision_site.id)
    |> preload(^preloads)
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
    |> where([d], not is_nil(d.label_id))
    |> preload([:label])
    |> Repo.all()
  end

  def list_decisions_for_classifier(%Classifier{} = classifier, opts \\ []) do
    preloads = Keyword.get(opts, :preloads, [])

    from(d in Decision, where: d.classifier_id == ^classifier.id)
    |> preload(^preloads)
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
  def get_decision!(id, opts \\ []) do
    preloads = Keyword.get(opts, :preloads, [])

    Decision
    |> Repo.get!(id)
    |> Repo.preload(preloads)
  end

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
    |> case do
      {:ok, decision} ->
        Phoenix.PubSub.broadcast(
          Excision.PubSub,
          "decision_site:#{decision.decision_site_id}",
          {:decision_created, %{decision: decision}}
        )

        {:ok, decision}

      x ->
        x
    end
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

  def label_decision(%Decision{} = decision, label_choice_id) do
    case update_decision(decision, %{label_id: label_choice_id}) do
      {:ok, updated_decision} ->
        updated_decision =
          get_decision!(updated_decision.id, preloads: [:classifier, :prediction, :label])

        if is_nil(decision.label) do
          Phoenix.PubSub.broadcast(
            Excision.PubSub,
            "decision_site:#{decision.decision_site_id}",
            {:label_created, %{decision: decision}}
          )
        end

        {:ok, updated_decision}

      x ->
        x
    end
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

  @doc """
  Returns the list of classifiers.

  ## Examples

      iex> list_classifiers()
      [%Classifier{}, ...]

  """
  def list_classifiers do
    Repo.all(Classifier)
  end

  def list_classifiers_for_decision_site(%DecisionSite{} = decision_site, opts \\ []) do
    preloads = Keyword.get(opts, :preloads, [])

    from(c in Classifier, where: c.decision_site_id == ^decision_site.id)
    # order by promoted_classifier first
    |> order_by([c], {
      :asc,
      fragment("CASE WHEN ? = ? THEN 0 ELSE 1 END", c.id, ^decision_site.promoted_classifier_id)
    })
    |> Repo.all()
    |> Repo.preload(preloads)
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
    |> Classifier.validate_base_model_name()
    |> Repo.insert()
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
    |> Classifier.validate_base_model_name()
    |> Repo.update()
  end

  def update_classifier_status(%Classifier{} = classifier, status) do
    classifier
    |> update_classifier(%{status: status})
    |> case do
      {:ok, classifier} ->
        Phoenix.PubSub.broadcast(
          Excision.PubSub,
          "classifier:#{classifier.id}",
          {:status_updated, status}
        )

        {:ok, classifier}

      x ->
        x
    end
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
    result = Repo.delete(classifier)

    if elem(result, 0) == :ok && classifier.checkpoint_path do
      File.rm_rf(classifier.checkpoint_path)
    end

    result
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

  @doc """
  Submits an Oban job to train the classifier
  """
  def train_classifier(classifier) do
    %{classifier_id: classifier.id}
    |> Excision.Workers.TrainClassifier.new()
    |> Oban.insert()
  end

  @doc """
  Promotes a classifier to the promoted_classifier for its decision_site
  """
  def promote_classifier(classifier) do
    classifier = Repo.preload(classifier, :decision_site)

    # TODO: transaction
    {:ok, _} =
      update_decision_site(
        classifier.decision_site,
        %{promoted_classifier_id: classifier.id}
      )

    update_classifier(classifier, %{promoted_at: DateTime.utc_now()})
  end

  def is_default_passthrough_classifier?(classifier) do
    classifier.name == Excision.Excisions.Classifier.default_passthrough_classifier().name
  end

  def build_label_map(decision_site) do
    decision_site = Repo.preload(decision_site, [:choices])

    decision_site.choices
    |> Enum.map(& &1.name)
    |> Enum.with_index()
    |> Enum.into(%{})
  end

  def compute_accuracy(%Classifier{} = classifier) do
    classifier = Repo.preload(classifier, :decisions)

    classifier.decisions
    |> Enum.filter(&(not is_nil(&1.label)))
    |> Enum.reduce({0, 0}, fn decision, {total, correct} ->
      {total + 1, correct + if(decision.label_id == decision.prediction_id, do: 1, else: 0)}
    end)
    |> then(fn {total, correct} ->
      if total == 0, do: nil, else: correct / total
    end)
  end

  def append_training_metrics(%Classifier{} = classifier, metrics) do
    classifier = get_classifier!(classifier.id)

    classifier
    |> Classifier.changeset(%{})
    |> Ecto.Changeset.put_embed(:training_metrics, [metrics | classifier.training_metrics],
      with: &Excision.Excisions.Classifier.training_metric_changeset/2
    )
    |> Repo.update()
    |> case do
      {:ok, classifier} ->
        :ok =
          Phoenix.PubSub.broadcast(
            Excision.PubSub,
            "classifier:#{classifier.id}",
            {:training_metrics_emitted, metrics}
          )

        {:ok, classifier}

      x ->
        x
    end
  end

  def clear_training_metrics(%Classifier{} = classifier) do
    classifier = get_classifier!(classifier.id)

    classifier
    |> Classifier.changeset(%{})
    |> Ecto.Changeset.put_embed(:training_metrics, [],
      with: &Excision.Excisions.Classifier.training_metric_changeset/2
    )
    |> Repo.update()
    |> case do
      {:ok, classifier} ->
        :ok =
          Phoenix.PubSub.broadcast(
            Excision.PubSub,
            "classifier:#{classifier.id}",
            {:training_metrics_cleared, nil}
          )

        {:ok, classifier}

      x ->
        x
    end
  end

  @doc """
  Returns the list of choices.

  ## Examples

      iex> list_choices()
      [%Choice{}, ...]

  """
  def list_choices do
    Repo.all(Choice)
  end

  @doc """
  Gets a single choice.

  Raises `Ecto.NoResultsError` if the Choice does not exist.

  ## Examples

      iex> get_choice!(123)
      %Choice{}

      iex> get_choice!(456)
      ** (Ecto.NoResultsError)

  """
  def get_choice!(id), do: Repo.get!(Choice, id)

  @doc """
  Creates a choice.

  ## Examples

      iex> create_choice(%{field: value})
      {:ok, %Choice{}}

      iex> create_choice(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_choice(attrs \\ %{}) do
    %Choice{}
    |> Choice.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a choice.

  ## Examples

      iex> update_choice(choice, %{field: new_value})
      {:ok, %Choice{}}

      iex> update_choice(choice, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_choice(%Choice{} = choice, attrs) do
    choice
    |> Choice.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a choice.

  ## Examples

      iex> delete_choice(choice)
      {:ok, %Choice{}}

      iex> delete_choice(choice)
      {:error, %Ecto.Changeset{}}

  """
  def delete_choice(%Choice{} = choice) do
    Repo.delete(choice)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking choice changes.

  ## Examples

      iex> change_choice(choice)
      %Ecto.Changeset{data: %Choice{}}

  """
  def change_choice(%Choice{} = choice, attrs \\ %{}) do
    Choice.changeset(choice, attrs)
  end
end
