defmodule Excision.Repo.Migrations.CreateDecisionSites do
  use Ecto.Migration

  def change do
    create table(:decision_sites) do
      add :name, :string
      add :active_classifier_id, references(:classifiers, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end
  end
end
