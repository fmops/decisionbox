# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Excision.Repo.insert!(%Excision.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Excision.Excisions
alias Excision.Excisions.Classifier

{:ok, decision_site} =
  Excisions.create_decision_site(%{
    name: "example"
  })

classifier =
  Excision.Repo.insert!(%Classifier{
    decision_site_id: decision_site.id,
    name: "example",
    status: :waiting
  })

for i <- 1..100 do
  {:ok, _} =
    Excisions.create_decision(%{
      decision_site_id: decision_site.id,
      # this is a test + random string
      input:
        "This is a test: " <>
          (:crypto.strong_rand_bytes(10) |> Base.encode16() |> String.downcase()),
      label: if(i <= 80, do: true, else: nil)
    })
end

for i <- 1..100 do
  {:ok, _} =
    Excisions.create_decision(%{
      decision_site_id: decision_site.id,
      input:
        "This is no longer a test: " <>
          (:crypto.strong_rand_bytes(10) |> Base.encode16() |> String.downcase()),
      label: if(i <= 80, do: false, else: nil)
    })
end
