defmodule Excision.Repo.Migrations.CreateDecisions do
  use Ecto.Migration

  def change do
    create table(:decisions) do
      add :input, :string
      add :prediction, :boolean, default: false, null: false
      add :label, :boolean, null: true
      add :decision_site_id, references(:decision_sites, on_delete: :nothing)
      add :classifier_id, references(:classifiers, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:decisions, [:decision_site_id])
    create index(:decisions, [:classifier_id])
  end
end
