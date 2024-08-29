defmodule Excision.Ontologies.Label do
  use Ecto.Schema
  import Ecto.Changeset

  schema "labels" do
    field :name, :string
    belongs_to :decision_site, Excision.Ontologies.DecisionSite

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(label, attrs) do
    label
    |> cast(attrs, [:name, :decision_site_id])
    |> validate_required([:name, :decision_site_id])
    |> foreign_key_constraint(:decision_site_id)
    |> unique_constraint([:decision_site_id, :name])
  end
end
