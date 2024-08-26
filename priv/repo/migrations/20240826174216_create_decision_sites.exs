defmodule Excision.Repo.Migrations.CreateDecisionSites do
  use Ecto.Migration

  def change do
    create table(:decision_sites) do
      add :name, :string

      timestamps(type: :utc_datetime)
    end
  end
end
