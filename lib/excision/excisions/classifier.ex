defmodule Excision.Excisions.Classifier do
  use Ecto.Schema
  import Ecto.Changeset

  schema "classifiers" do
    field :name, :string
    belongs_to :decision_site, Excision.Excisions.DecisionSite
    has_many :decisions, Excision.Excisions.Decision

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(classifier, attrs) do
    classifier
    |> cast(attrs, [:name, :decision_site_id])
    |> validate_required([:name])
    |> foreign_key_constraint(:decision_site)
  end

  def default_baseline_classifier do
    %__MODULE__{name: "baseline"}
  end
end
