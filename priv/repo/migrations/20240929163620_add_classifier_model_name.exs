defmodule Excision.Repo.Migrations.AddClassifierModelName do
  use Ecto.Migration

  def change do

    # add column model_name with default value
    alter table(:classifiers) do
      add :model_name, :string, null: false, default: Excision.Excisions.Classifier.default_model_name()
    end

  end
end
