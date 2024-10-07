defmodule Excision.Repo.Migrations.AddClassifierModelName do
  use Ecto.Migration

  def change do
    # add nullable column base_model_name
    alter table(:classifiers) do
      add :base_model_name, :string, null: true, default: "distilbert/distilbert-base-uncased"
    end
  end
end
