defmodule EctoSessionsDemo.Sessions do
  use EctoSessions,
    repo: EctoSessionsDemo.Repo,
    table_name: "sessions",
    extra_fields: [
      {&Ecto.Schema.field/2, [:user_id, :binary]}
      # TODO: {&Ecto.Schema.belongs_to/2, [:user, :user]}
    ]
end
