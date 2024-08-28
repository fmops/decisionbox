defmodule Excision.Repo.Migrations.AddTrainingMetricsToClassifier do
  use Ecto.Migration

  def change do
    alter table(:classifiers) do
      add :training_metrics, :map
    end
  end
end
