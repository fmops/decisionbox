defmodule Excision.Repo.Migrations.AlterDecisionsToUseChoices do
  use Ecto.Migration

  def up do
    alter table(:decisions) do
      remove :label
      remove :prediction
      add :label_id, references(:choices, on_delete: :delete_all)
      add :prediction_id, references(:choices, on_delete: :delete_all)
    end

    create index(:decisions, [:label_id])
    create index(:decisions, [:prediction_id])
  end

  def down do
    alter table(:decisions) do
      remove :label_id
      remove :prediction_id
      add :label, :boolean
      add :prediction, :boolean
    end

    drop index(:decisions, [:label_id])
    drop index(:decisions, [:prediction_id])
  end
end
