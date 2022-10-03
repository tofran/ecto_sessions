defmodule EctoSessionsDemo.Repo.Migrations.CreateSessions do
  use Ecto.Migration

  alias EctoSessions.Migrations

  def up,
    do:
      Migrations.up(
        table_name: "sessions",
        extra_fields: [{:user_id, :string}],
        create_extra_field_indexes: true
      )

  def down, do: Migrations.down()
end
