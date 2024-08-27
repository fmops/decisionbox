defmodule Excision.Repo.Migrations.CreateClassifiers do
  use Ecto.Migration

  def change do
    create table(:classifiers) do
      add :name, :string
      add :decision_site_id, references(:decision_sites, on_delete: :delete_all)
      add :status, :string, null: false, default: "waiting"

      timestamps(type: :utc_datetime)
    end

    create index(:classifiers, [:decision_site_id])
  end
end
