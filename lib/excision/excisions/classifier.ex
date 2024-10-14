defmodule Excision.Excisions.Classifier do
  use Ecto.Schema
  import Ecto.Changeset

  def default_model_name do
    "distilbert/distilbert-base-uncased"
  end

  schema "classifiers" do
    field :name, :string
    field :base_model_name, :string, default: "distilbert/distilbert-base-uncased"
    field :status, Ecto.Enum, values: [:waiting, :failed, :training, :trained], default: :waiting
    field :checkpoint_path, :string
    field :train_accuracy, :float
    field :test_accuracy, :float
    field :trained_at, :utc_datetime
    field :promoted_at, :utc_datetime

    embeds_one :training_parameters, TrainingParameters, primary_key: false do
      @derive Jason.Encoder
      field :learning_rate, :float
      field :batch_size, :integer
      field :sequence_length, :integer
      field :epochs, :integer
    end

    embeds_many :training_metrics, TrainingMetric, primary_key: false, on_replace: :delete do
      field :timestamp, :utc_datetime
      field :epoch, :integer
      field :iteration, :integer
      field :loss, :float
      field :accuracy, :float
    end

    belongs_to :decision_site, Excision.Excisions.DecisionSite
    has_many :decisions, Excision.Excisions.Decision

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(classifier, attrs) do
    classifier
    |> cast(attrs, [
      :name,
      :base_model_name,
      :decision_site_id,
      :status,
      :checkpoint_path,
      :train_accuracy,
      :test_accuracy,
      :trained_at,
      :promoted_at
    ])
    |> cast_embed(:training_parameters, with: &training_parameters_changeset/2)
    |> validate_required([:name])
    |> foreign_key_constraint(:decision_site)
  end

  def training_parameters_changeset(training_parameters, attrs \\ %{}) do
    training_parameters
    |> cast(attrs, [:learning_rate, :batch_size, :sequence_length, :epochs])
    |> validate_required([:learning_rate, :batch_size, :sequence_length, :epochs])
    |> validate_number(:learning_rate, greater_than: 0.0)
    |> validate_number(:batch_size, greater_than: 0)
    |> validate_number(:sequence_length, greater_than: 0)
    |> validate_number(:epochs, greater_than: 0)
  end

  def training_metric_changeset(training_metrics, attrs \\ %{}) do
    training_metrics
    |> cast(attrs, [:timestamp, :loss, :accuracy])
    |> validate_required([:timestamp, :loss, :accuracy])
  end

  def default_baseline_classifier do
    %__MODULE__{
      name: "baseline",
      status: :trained,
      training_parameters: %__MODULE__.TrainingParameters{}
    }
  end

  def status_to_display_status(:trained), do: :ready
  def status_to_display_status(s), do: s
end
