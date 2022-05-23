defmodule EctoSessionsDemo.Repo do
  use Ecto.Repo,
    otp_app: :ecto_sessions_demo,
    adapter: Ecto.Adapters.Postgres
end
