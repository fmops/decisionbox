defmodule Excision.Repo.Migrations.CreateChoices do
  use Ecto.Migration

  def change do
    create table(:choices) do
      add :name, :string
      add :decision_site_id, references(:decision_sites, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:choices, [:decision_site_id])
    create unique_index(:choices, [:name, :decision_site_id])
  end
end
