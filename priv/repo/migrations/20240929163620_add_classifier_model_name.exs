defmodule Excision.Repo.Migrations.AddClassifierModelName do
  use Ecto.Migration

  def change do
    # add nullable column base_model_name
    # if base_model_name not provided, distilbert/distilbert-base-uncased is set
    # app may not work as expected until you run the migration
    alter table(:classifiers) do
      add :base_model_name, :string, null: true, default: "distilbert/distilbert-base-uncased"
    end
  end
end
