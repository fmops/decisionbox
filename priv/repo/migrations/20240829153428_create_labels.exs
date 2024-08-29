defmodule Excision.Repo.Migrations.CreateLabels do
  use Ecto.Migration

  def change do
    create table(:labels) do
      add :name, :string
      add :decision_site_id, references(:decision_sites, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:labels, [:decision_site_id])
    create unique_index(:labels, [:name, :decision_site_id])
  end
end
