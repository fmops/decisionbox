defmodule Excision.Excisions.Decision do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {
    Flop.Schema,
    filterable: [:label_id], sortable: [:inserted_at]
  }

  schema "decisions" do
    field :input, :string
    belongs_to :label, Excision.Excisions.Choice
    belongs_to :prediction, Excision.Excisions.Choice
    belongs_to :decision_site, Excision.Excisions.DecisionSite
    belongs_to :classifier, Excision.Excisions.Classifier

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(decision, attrs) do
    decision
    |> cast(attrs, [:input, :prediction_id, :label_id, :decision_site_id, :classifier_id])
    |> validate_required([:input, :prediction_id, :decision_site_id])
    |> foreign_key_constraint(:prediction)
    |> foreign_key_constraint(:label)
    |> foreign_key_constraint(:decision_site)
    |> foreign_key_constraint(:classifier)
  end
end
