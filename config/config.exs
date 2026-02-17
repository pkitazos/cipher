# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :cipher, :scopes,
  user: [
    default: true,
    module: Cipher.Accounts.Scope,
    assign_key: :current_scope,
    access_path: [:user, :id],
    schema_key: :user_id,
    schema_type: :id,
    schema_table: :users,
    test_data_fixture: Cipher.AccountsFixtures,
    test_setup_helper: :register_and_log_in_user
  ]

config :cipher,
  generators: [timestamp_type: :utc_datetime],
  ecto_repos: [Cipher.Repo]

# Configure the endpoint
config :cipher, CipherWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: CipherWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Cipher.PubSub,
  live_view: [signing_salt: "y2lnQVJT"]

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :cipher, Cipher.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild
config :esbuild,
  version: "0.23.0",
  cipher: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind v4
config :tailwind,
  version: "4.1.10",
  cipher: [
    args: ~w(
        --input=css/app.css
        --output=../priv/static/assets/app.css
      ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
