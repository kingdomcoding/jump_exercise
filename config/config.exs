# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :ash_oban, pro?: false

config :jump_exercise, Oban,
  engine: Oban.Engines.Basic,
  notifier: Oban.Notifiers.Postgres,
  queues: [default: 10, chat_responses: [limit: 10], conversations: [limit: 10]],
  repo: JumpExercise.Repo,
  plugins: [{Oban.Plugins.Cron, []}]

config :spark, formatter: ["Ash.Resource": [section_order: [:authentication, :tokens, :postgres]]]

config :jump_exercise,
  ecto_repos: [JumpExercise.Repo],
  generators: [timestamp_type: :utc_datetime],
  ash_domains: [
    JumpExercise.Gmail,
    JumpExercise.Chat,
    JumpExercise.Accounts
  ]

# Configures the endpoint
config :jump_exercise, JumpExerciseWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: JumpExerciseWeb.ErrorHTML, json: JumpExerciseWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: JumpExercise.PubSub,
  live_view: [signing_salt: "jbLw23vL"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :jump_exercise, JumpExercise.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  jump_exercise: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.3",
  jump_exercise: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
