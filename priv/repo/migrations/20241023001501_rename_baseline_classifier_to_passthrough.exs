defmodule Excision.Repo.Migrations.RenameBaselineClassifierToPassthrough do
  use Ecto.Migration

  import Ecto.Query
  alias Excision.Repo

  def change do
    # fetches all classifiers with name "baseline" and renames them to "passthrough"
    baseline_classifiers =
      Excision.Excisions.Classifier
      |> where(name: "baseline")
      |> Repo.all()

    for classifier <- baseline_classifiers do
      classifier
      |> Excision.Excisions.Classifier.changeset(%{name: "passthrough"})
      |> Repo.update()
    end
  end
end
