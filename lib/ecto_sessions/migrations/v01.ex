defmodule EctoSessions.Migrations.V01 do
  @moduledoc false

  use Ecto.Migration

  def up(%{
        prefix: prefix,
        create_schema: create_schema,
        sessions_table_name: sessions_table_name,
        extra_fields: extra_fields,
        create_extra_field_indexes: create_extra_field_indexes
      }) do
    if create_schema, do: execute("CREATE SCHEMA IF NOT EXISTS #{prefix}")

    create_if_not_exists table(sessions_table_name, primary_key: false, prefix: prefix) do
      add(:id, :binary_id, primary_key: true)
      add(:auth_token, :string, null: false)
      add(:data, :map, default: %{}, null: false)
      add(:expires_at, :utc_datetime_usec, null: true)

      for {field_name, field_type} <- extra_fields do
        add(field_name, field_type, null: false)
      end

      timestamps(type: :utc_datetime_usec)
    end

    create(unique_index(sessions_table_name, [:auth_token]))

    if create_extra_field_indexes do
      for {field_name, _field_type} <- extra_fields do
        create(index(sessions_table_name, [field_name]))
      end
    end
  end

  def down(%{
        sessions_table_name: sessions_table_name,
        prefix: prefix
      }) do
    drop_if_exists(table(sessions_table_name, prefix: prefix))
  end
end
