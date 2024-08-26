defmodule Excision.Repo do
  use Ecto.Repo,
    otp_app: :excision,
    adapter: Ecto.Adapters.SQLite3
end
