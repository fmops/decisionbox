defmodule Excision.Excisions.Decision do
  use Ecto.Schema
  import Ecto.Changeset

  schema "decisions" do
    field :input, :string
    field :label, :boolean
    field :prediction, :boolean, default: false
    belongs_to :decision_site, Excision.Excisions.DecisionSite
    belongs_to :classifier, Excision.Excisions.Classifier

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(decision, attrs) do
    decision
    |> cast(attrs, [:input, :prediction, :label, :decision_site_id, :classifier_id])
    |> validate_required([:input, :prediction, :decision_site_id])
    |> foreign_key_constraint(:decision_site)
    |> foreign_key_constraint(:classifier)
  end
end
