import Config

config :ecto_sessions_demo,
  ecto_repos: [EctoSessionsDemo.Repo],
  generators: [binary_id: true]

# Configures the endpoint
config :ecto_sessions_demo, EctoSessionsDemoWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: EctoSessionsDemoWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: EctoSessionsDemo.PubSub

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
