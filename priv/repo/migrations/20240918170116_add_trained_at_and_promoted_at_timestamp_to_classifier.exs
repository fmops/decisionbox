defmodule Excision.Repo.Migrations.AddTrainedAtAndPromotedAtTimestampToClassifier do
  use Ecto.Migration

  def change do
    alter table(:classifiers) do
      add :trained_at, :utc_datetime, null: true
      add :promoted_at, :utc_datetime, null: true
    end
  end
end
