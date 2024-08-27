defmodule Excision.Repo.Migrations.AddStatusToClassifier do
  use Ecto.Migration

  def change do
    alter table(:classifiers) do
      add :status, :string, null: false, default: "waiting"
    end
  end
end
