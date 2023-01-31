import Config

config :ecto_sessions_demo, EctoSessionsDemo.Repo, pool: Ecto.Adapters.SQL.Sandbox

config :ecto_sessions_demo, EctoSessionsDemoWeb.Endpoint,
  http: [
    ip: {127, 0, 0, 1},
    port: 4002
  ],
  secret_key_base: "Rdh/hov72Mj10d0Y66dCcM3nqadbj31LWgAOJiQE5W6Ra7rJHafZEYGxoYhyQry9",
  server: false

config :logger, level: :warn

config :phoenix, :plug_init_mode, :runtime
