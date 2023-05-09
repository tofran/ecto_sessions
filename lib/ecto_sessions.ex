defmodule EctoSessions do
  @default_table_name "sessions"
  @default_extra_fields [
    {:field, [:user_id, :string]}
  ]

  @moduledoc """
  This lib implements a set of methods to help you handle the storage and
  access to database-backend sessions with ecto.

  In your application, use `EctoSessions`:

  ```elixir
  defmodule MyApp.Sessions do
    use EctoSessions,
      repo: MyApp.Repo,
      prefix: nil,
      table_name: #{inspect(@default_table_name)},
      extra_fields: #{inspect(@default_extra_fields)}
  end
  ```

  Parameters:

    - `repo`: your ecto repo module, required. Ex: `MyApp.Repo`.
    - `prefix`: ecto prefix, optional, default to `nil`.
    - `table_name`: The table name for these sessions.
      Create a module using `EctoSessions` for each table, ex: Sessions, ApiKeys, etc.
    - `extra_fields`: Extra, custom, high-level, fields (columns) for the session schema.

  See `EctoSessions.Migrations` for instructions on how to migrate your
  database.
  """

  defmacro __using__(opts) do
    ecto_sessions_module = __CALLER__.module

    repo = Keyword.fetch!(opts, :repo)
    prefix = Keyword.get(opts, :prefix, nil)
    table_name = Keyword.get(opts, :table_name, @default_table_name)
    extra_fields = Keyword.get(opts, :extra_fields, @default_extra_fields)

    quote do
      defmodule Config do
        use EctoSessions.Config,
          ecto_sessions_module: unquote(ecto_sessions_module)
      end

      defmodule Session do
        use EctoSessions.Session,
          config_module: unquote(Module.concat([ecto_sessions_module, Config])),
          table_name: unquote(table_name),
          extra_fields: unquote(Macro.escape(extra_fields))
      end

      import Ecto.Query
      alias EctoSessions.AuthToken

      @repo unquote(repo)

      def create_session(attrs \\ %{}) do
        Session.changeset(attrs)
        |> @repo.insert(prefix: unquote(prefix))
      end

      def create_session!(attrs \\ %{}) do
        Session.changeset(attrs)
        |> @repo.insert!(prefix: unquote(prefix))
      end

      def get_sessions_query(filters, options \\ []) do
        preload = Keyword.get(options, :preload, [])
        delete_query = Keyword.get(options, :delete_query, false)

        if delete_query do
          from(session in Session)
        else
          from(session in Session,
            preload: ^preload,
            order_by: [desc: session.inserted_at],
            select: %{
              session
              | is_expired:
                  is_nil(session.expires_at) or
                    session.expires_at <= ^DateTime.utc_now()
            }
          )
        end
        |> filter_session_query(filters)
      end

      def filter_session_query(query, filters) when is_list(filters) do
        filters = Keyword.put_new(filters, :status, :valid)

        Enum.reduce(
          filters,
          query,
          fn {field, value}, query_acc ->
            filter_session_query_by(query_acc, field, value)
          end
        )
      end

      def filter_session_query_by(query, :status, :all), do: query

      def filter_session_query_by(query, :status, :valid) do
        from(
          session in query,
          where:
            is_nil(session.expires_at) or
              session.expires_at > ^DateTime.utc_now()
        )
      end

      def filter_session_query_by(query, :status, :expired) do
        from(
          session in query,
          where:
            not is_nil(session.expires_at) and
              session.expires_at <= ^DateTime.utc_now()
        )
      end

      def filter_session_query_by(query, :status, status) do
        raise RuntimeError, "Invalid status #{status}"
      end

      def filter_session_query_by(query, :auth_token, nil) do
        from(session in query, where: false)
      end

      def filter_session_query_by(query, :auth_token, plaintext_auth_token) do
        auth_token_digest =
          AuthToken.get_digest(
            plaintext_auth_token,
            Config.get_hashing_algorithm(),
            Config.get_secret_salt()
          )

        from(
          session in query,
          where: session.auth_token_digest == ^auth_token_digest
        )
      end

      def filter_session_query_by(query, :plaintext_auth_token, plaintext_auth_token) do
        filter_session_query_by(query, :auth_token, plaintext_auth_token)
      end

      def filter_session_query_by(query, field_name, value) do
        from(
          session in query,
          where: field(session, ^field_name) == ^value
        )
      end

      def get_session(filters, options \\ []) when is_list(filters) do
        get_sessions_query(filters, options)
        |> @repo.one(prefix: unquote(prefix))
        |> maybe_extend_session(options)
      end

      def get_session!(filters, options \\ []) do
        get_sessions_query(filters, options)
        |> @repo.one!(prefix: unquote(prefix))
        |> maybe_extend_session(options)
      end

      def list_sessions(filters, options \\ []) do
        get_sessions_query(filters, options)
        |> @repo.all(prefix: unquote(prefix))
      end

      def list_valid_sessions(filters, options \\ []) do
        get_sessions_query(filters, options)
        |> @repo.all(prefix: unquote(prefix))
      end

      def extend_session(session) do
        Session.changeset(session)
        |> update_session!()
      end

      def expire_session!(session) do
        Session.expire_changeset(session)
        |> update_session!()
      end

      def delete_session(session) do
        session
        |> @repo.delete(prefix: unquote(prefix))
      end

      def delete_session!(session) do
        session
        |> @repo.delete!(prefix: unquote(prefix))
      end

      def update_session!(changeset) do
        @repo.update!(changeset)
      end

      def count(filters \\ [], options \\ []) do
        get_sessions_query(filters, options)
        |> @repo.aggregate(:count, prefix: unquote(prefix))
      end

      def delete_expired() do
        {delete_count, _} =
          get_sessions_query([status: :expired], delete_query: true)
          |> @repo.delete_all(prefix: unquote(prefix))

        delete_count
      end

      defp maybe_extend_session({:ok, session}, options) do
        {
          :ok,
          maybe_extend_session(session, options)
        }
      end

      defp maybe_extend_session(%Session{} = session, options) do
        should_extend_session =
          Keyword.get(
            options,
            :should_extend_session,
            Config.get_auto_extend_session()
          )

        if should_extend_session do
          extend_session(session)
        end

        session
      end

      defp maybe_extend_session(result, options), do: result
    end
  end

  @doc """
  Creates a session. `attrs` is a map that contains `EctoSessions.Session` attributes,
  where the keys are atoms.

  Uses `Ecto.Repo.insert`

  ## Examples

      iex> create_session(%{user_id: "1234", data: %{device_name: "Sample Browser"}})
      %Session{
        user_id: "1234",
        data: %{
          device_name: "Sample Browser",
          auth_token: "plaintext-auth-token"
          auth_token_digest: "hashed-token"
        }
      }
  """
  @callback create_session(attrs :: map) :: Ecto.Schema.t()

  @doc """
  Same as `create_session/1` but using `Ecto.Repo.insert!`.
  """
  @callback create_session!(filters :: map, options :: list) :: Ecto.Schema.t()

  @doc """
  Retrieves a query to the sessions.

  Options:
   - `delete_query`: Boolean that indicates a delete query a
     should be returned. Instead of a select one (the default: false).
   - `preload`: Shorthand for `preload` query argument.

  """
  @callback get_sessions_query(attrs :: any) :: Ecto.Query.t()

  @doc """
  Filters a session query.
  """
  @callback filter_session_query(query :: Ecto.Queryable.t(), filters :: any) ::
              Ecto.Queryable.t()

  @doc """
  Filters a session query by the given argument.
  """
  @callback filter_session_query_by(query :: any, filters :: any) :: Ecto.Queryable.t()

  @doc """
  Retrieves a session from the database.

  Options:

  - `preload`: ecto preloads, see `get_sessions_query/1`.
  - `auto_extend_session`: override the default `auto_extend_session` config
    (`Config.get_auto_extend_session()`). `true` will perform session extending,
    `false` to prevent this behaviour.
  """
  @callback get_session(filters :: any, options :: list) :: {atom, Ecto.Schema.t()}

  @doc """
  Retrieves a session from the database using `Ecto.Repo.one!`

  See `get_session/2` for more information.
  """
  @callback get_session!(filters :: any, options :: list) :: Ecto.Schema.t()

  @doc """
  Retrieve sessions matching the provided filters.
  """
  @callback list_sessions(filters :: any, options :: list) :: list(Ecto.Queryable.t())

  @doc """
  Retrieve valid sessions matching the provided filters.
  """
  @callback list_valid_sessions(filters :: any, options :: list) :: list(Ecto.Queryable.t())

  @doc """
  Given a session, ensure `expires_at` is updated according to the `EctoSessions.Config`.
  """
  @callback extend_session(Ecto.Schema.t()) :: Ecto.Schema.t()

  @doc """
  Deletes the session using `Ecto.Repo.delete`.
  """
  @callback delete_session(Ecto.Schema.t()) :: {atom, any}

  @doc """
  Deletes the session using `Ecto.Repo.delete!`.
  """
  @callback delete_session!(Ecto.Schema.t()) :: any

  @doc """
  Updates a session using `Ecto.Repo.update!`.
  """
  @callback update_session!(Ecto.Changeset.t()) :: Ecto.Schema.t()

  @doc """
  Count the sessions matching the provided filters.
  """
  @callback count(Ecto.Changeset.t()) :: Ecto.Schema.t()

  @doc """
  Deletes expired sessions.
  """
  @callback delete_expired(Ecto.Changeset.t()) :: Ecto.Schema.t()
end
