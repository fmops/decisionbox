defmodule Excision.Repo.Migrations.RenameActiveClassifierToDefault do
  use Ecto.Migration

  def change do
    rename table(:decision_sites), :active_classifier_id, to: :default_classifier_id
  end
end
