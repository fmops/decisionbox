defmodule Excision.Excisions.DecisionSite do
  use Ecto.Schema
  import Ecto.Changeset

  schema "decision_sites" do
    field :name, :string
    belongs_to :promoted_classifier, Excision.Excisions.Classifier
    has_many :choices, Excision.Excisions.Choice, on_replace: :delete
    has_many :classifiers, Excision.Excisions.Classifier
    has_many :decisions, Excision.Excisions.Decision

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(decision_site, attrs) do
    decision_site
    |> cast(attrs, [:name, :promoted_classifier_id])
    |> cast_assoc(:choices,
      sort_param: :choices_sort,
      drop_param: :choices_drop
    )
    |> validate_required([:name, :promoted_classifier_id])
    |> foreign_key_constraint(:promoted_classifier)
  end
end
