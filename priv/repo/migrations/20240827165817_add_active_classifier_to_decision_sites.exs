defmodule Excision.Repo.Migrations.AddActiveClassifierToDecisionSites do
  use Ecto.Migration

  def change do
    alter table(:decision_sites) do
      add :active_classifier_id, references(:classifiers, on_delete: :nilify_all)
    end
  end
end
