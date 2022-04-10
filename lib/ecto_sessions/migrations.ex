defmodule EctoSessions.Migrations do
  @moduledoc """
  Run the migrations needed to have ecto_sessions table and indexes.
  If you are just starting use this interface instead of calling migrations directly.

  ## How-to

  Create a migration with `mix ecto.gen.migration AddEctoSessions`,
  then paste the following:

  ```
  defmodule MyApp.Repo.Migrations.AddEctoSessions do
    use Ecto.Migration

    alias EctoSessions.Migrations

    def up, do: Migrations.up(%{
      table_name: "sessions",
      extra_fields: [{:user_id, :string}],
      create_extra_field_indexes: true
    })

    def down, do: Migrations.down()
  end
  ```

  Tweak the options according to your `EctoSessions` setup.
  """

  @default_prefix "public"
  @default_table_name "sessions"
  @default_extra_fields [{:user_id, :string}]
  @default_create_schema true

  @doc """
  Migartes EctoSessions up. Options:

   - `prefix`: The database prefix, as documented in `Ecto.Repo`, default to #{@default_prefix}
   - `create_schema`: If the schema should be created.
   - `table_name`: The session table name, defaults to `#{@default_table_name}`.
   - `extra_fields`: A list of tuples for the extra fields to create.
      Defaults to `#{inspect(@default_extra_fields)}`.
   - `create_extra_field_indexes`: true to create unique indexes for the extra fields.
      Defaults to `#{@default_create_schema}`.
  """
  def up(opts \\ []) do
    opts
    |> get_change_opts()
    |> EctoSessions.Migrations.V01.up()
  end

  def down(opts \\ []) do
    opts
    |> get_change_opts()
    |> EctoSessions.Migrations.V01.down()
  end

  defp get_change_opts(opts) do
    prefix = Keyword.get(opts, :prefix, @default_prefix)

    %{
      prefix: prefix,
      create_schema: Keyword.get(opts, :create_schema, prefix != @default_prefix),
      table_name: Keyword.get(opts, :table_name, @default_table_name),
      extra_fields: Keyword.get(opts, :extra_fields, @default_extra_fields),
      create_extra_field_indexes:
        Keyword.get(opts, :create_extra_field_indexes, @default_create_schema)
    }
  end
end
