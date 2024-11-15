defmodule Excision.Repo.Migrations.RenameDefaultClassifierToPromoted do
  use Ecto.Migration

  def change do
    rename table(:decision_sites), :default_classifier_id, to: :promoted_classifier_id
  end
end
