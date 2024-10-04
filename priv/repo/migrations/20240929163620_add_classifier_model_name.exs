defmodule Excision.Repo.Migrations.AddClassifierModelName do
  use Ecto.Migration

  def change do
    # add nullable column model_name
    alter table(:classifiers) do
      add :model_name, :string, null: true
    end
  end
end
