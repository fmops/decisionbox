import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :excision, Excision.Repo,
  database: Path.expand("../excision_test.db", __DIR__),
  pool_size: 5,
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :excision, ExcisionWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "PQTV3eKvPlJu7QjmuT785MwhtmYdJgiuJ30EsxbcsjexbGGiyw89ENUSxIU2cBeW",
  server: false

# In test we don't send emails
config :excision, Excision.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

config :excision,
  openai_chat_completions_url: "http://localhost:4001/v1/chat/completions"

config :excision, Oban, testing: :inline
