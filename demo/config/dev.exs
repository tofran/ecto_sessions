import Config

config :ecto_sessions_demo, EctoSessionsDemo.Repo,
  stacktrace: true,
  show_sensitive_data_on_connection_error: true

config :ecto_sessions_demo, EctoSessionsDemoWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  code_reloader: true,
  check_origin: false,
  debug_errors: true

config :ecto_sessions_demo, EctoSessionsDemoWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/ecto_sessions_demo_web/(live|views)/.*(ex)$",
      ~r"lib/ecto_sessions_demo_web/templates/.*(eex)$"
    ]
  ]

config :logger, :console, format: "[$level] $message\n"

config :phoenix, :stacktrace_depth, 20

config :phoenix, :plug_init_mode, :runtime
