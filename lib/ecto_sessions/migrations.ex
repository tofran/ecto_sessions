defmodule EctoSessions.Migrations do
  @moduledoc """
  """

  alias EctoSessions.Config

  @default_prefix "public"

  def up(opts \\ []) do
    prefix = Keyword.get(opts, :prefix, @default_prefix)

    opts = %{
      prefix: prefix,
      create_schema: Keyword.get(opts, :create_schema, prefix != @default_prefix),
      extra_fields: Keyword.get(opts, :extra_fields, Config.get_extra_fields()),
      sessions_table_name:
        Keyword.get(opts, :sessions_table_name, Config.get_sessions_table_name()),
      create_extra_field_indexes: Keyword.get(opts, :create_extra_field_indexes, true)
    }

    EctoSessions.Migrations.V01.up(opts)
  end

  def down(opts \\ []) do
    opts = %{
      prefix: Keyword.get(opts, :prefix, @default_prefix),
      sessions_table_name:
        Keyword.get(opts, :sessions_table_name, Config.get_sessions_table_name()),
      create_extra_field_indexes: Keyword.get(opts, :create_extra_field_indexes, true)
    }

    EctoSessions.Migrations.V01.down(opts)
  end
end
