defmodule EctoSessionsDemo.Sessions do
  use EctoSessions,
    repo: EctoSessionsDemo.Repo,
    table_name: "sessions",
    extra_fields: [
      {:field, [:user_id, :binary]}
    ]
end
