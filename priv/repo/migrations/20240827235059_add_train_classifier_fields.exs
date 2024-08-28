defmodule Excision.Repo.Migrations.AddTrainClassifierFields do
  use Ecto.Migration

  def change do
    alter table(:classifiers) do
      add :checkpoint_path, :string
      add :train_accuracy, :float
      add :test_accuracy, :float
    end
  end
end
