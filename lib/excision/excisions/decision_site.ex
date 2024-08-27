defmodule Excision.Excisions.DecisionSite do
  use Ecto.Schema
  import Ecto.Changeset

  schema "decision_sites" do
    field :name, :string
    belongs_to :active_classifier, Excision.Excisions.Classifier
    has_many :classifiers, Excision.Excisions.Classifier, on_delete: :delete_all
    has_many :decisions, Excision.Excisions.Decision, on_delete: :delete_all

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(decision_site, attrs) do
    decision_site
    |> cast(attrs, [:name, :active_classifier_id])
    |> validate_required([:name, :active_classifier_id])
    |> foreign_key_constraint(:active_classifier)
  end
end
