defmodule Excision.Excisions.DecisionSite do
  use Ecto.Schema
  import Ecto.Changeset

  schema "decision_sites" do
    field :name, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(decision_site, attrs) do
    decision_site
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
