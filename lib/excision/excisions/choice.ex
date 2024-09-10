defmodule Excision.Excisions.Choice do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [
    :id,
    :name,
    :decision_site_id,
    :inserted_at,
    :updated_at
  ]}
  schema "choices" do
    field :name, :string
    belongs_to :decision_site, Excision.Excisions.DecisionSite

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
