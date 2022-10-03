import Config

fetch_env = fn env_name ->
  System.get_env(env_name) || raise "Required environment variable '#{env_name}' is missing."
end

config :ecto_sessions_demo, EctoSessionsDemo.Repo,
  url: fetch_env.("DATABASE_URL"),
  socket_options:
    if(
      System.get_env("DATABASE_IPV6_ONLY") == "true",
      do: [:inet6],
      else: [:inet, :inet6]
    ),
  log: :info,
  pool_size: 10,
  timeout: 190_000,
  connect_timeout: 10_000,
  migration_timestamps: [
    type: :utc_datetime_usec
  ]

if config_env() != :test do
  %{
    host: host,
    port: port,
    scheme: scheme
  } = URI.parse(fetch_env.("PHOENIX_URL"))

  config :ecto_sessions_demo, EctoSessionsDemoWeb.Endpoint,
    server: true,
    secret_key_base: fetch_env.("PHOENIX_SECRET_KEY_BASE"),
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: 4000
    ],
    url: [
      host: host,
      port: port,
      scheme: scheme
    ]
end
