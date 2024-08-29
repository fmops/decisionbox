defmodule Excision.Repo.Migrations.AddTrainingParametersToClassifiers do
  use Ecto.Migration

  def change do
    alter table(:classifiers) do
      add :training_parameters, :map, null: false
    end
  end
end
