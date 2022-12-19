defmodule EctoSessions do
  @default_table_name "sessions"
  @default_extra_fields [
    {Ecto.Schema, :field, [:user_id, :string]}
  ]

  @moduledoc """
  This lib implements a set of methods to help you handle the storage and
  access to database-backend sessions.

  In your application, use `EctoSessions`:

  ```elixir
  defmodule MyApp.Sessions do
    use EctoSessions,
      repo: MyApp.Repo, # required
      prefix: nil, # optional
      table_name: #{inspect(@default_table_name)}, # optional
      extra_fields: #{inspect(@default_extra_fields)} # optional
  end
  ```

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

      def get_auth_token_from_new_session(attrs \\ %{}) do
        %{auth_token: auth_token} = create_session!(attrs)
        auth_token
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
        filters = Keyword.put_new(filters, :include_expired, false)

        Enum.reduce(
          filters,
          query,
          fn {field, value}, query_acc ->
            filter_session_query_by(query_acc, field, value)
          end
        )
      end

      def filter_session_query_by(query, :include_expired, false) do
        from(
          session in query,
          where:
            is_nil(session.expires_at) or
              session.expires_at > ^DateTime.utc_now()
        )
      end

      def filter_session_query_by(query, :include_expired, true), do: query

      def filter_session_query_by(query, :only_expired, true) do
        from(
          session in query,
          where:
            not is_nil(session.expires_at) or
              session.expires_at <= ^DateTime.utc_now()
        )
      end

      def filter_session_query_by(query, :only_expired, false), do: query

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
      end

      def get_session!(filters, options \\ []) do
        get_sessions_query(filters, options)
        |> @repo.one!(prefix: unquote(prefix))
      end

      def list_sessions(filters, options \\ []) do
        get_sessions_query(options)
        |> filter_session_query(filters)
        |> @repo.all(prefix: unquote(prefix))
      end

      def list_valid_sessions(filters, options \\ []) do
        get_sessions_query(options)
        |> filter_session_query(filters)
        |> @repo.all(prefix: unquote(prefix))
      end

      def renovate_session(session) do
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
    end
  end

  @doc """
  Creates a session. `attrs` is a map that contains `EctoSessions.Session` attributes,
  where the keys are atoms.

  Uses `Ecto.Repo.insert/2`

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
  Same as `create_session/1` but using `Ecto.Repo.insert!/2`.
  """
  @callback create_session!(attrs :: map) :: Ecto.Schema.t()

  @doc """
  Creates a session using `create_session!/1` returning only the plaintext auth token.

  ## Examples

      iex> create_session(%{user_id: "1234", data: %{device_name: "Sample Browser"}})
      "plaintext-auth-token"

  """
  @callback create_auth_token(attrs :: map()) :: Ecto.Schema.t()

  @doc """
  Returns an ecto query for sessions which have expired:
  Whenever expires_at is in the past.
  """
  @callback get_expired_sessions_query() :: Ecto.Queryable.t()

  @doc """
  Returns an ecto query for sessions which have not expired:
  Whenever expires_at is either null or in the future.
  """
  @callback get_valid_sessions_query() :: Ecto.Queryable.t()

  @doc """
  Filters a sessions query by the given field.

  When `:auth_token` is passed, hashing will be automatically handled according to
  the configuration.
  """
  @callback filter_session_query_by(query :: Ecto.Queryable.t(), field_name :: atom, value :: any) ::
              Ecto.Queryable.t()

  @doc """
  Returns a valid session given the field name and the desired value to check.

  Uses `Ecto.Repo.one/1`
  """
  @callback get_session(field_name :: atom, value :: any) :: Ecto.Schema.t()

  @doc """
  Same as `get_session/2` but using `Ecto.Repo.one!/1`.
  """
  @callback get_session!(field_name :: atom, value :: any) :: Ecto.Schema.t()

  @doc """
  Renovates a session expiration following the configuration in `EctoSession.Config`.
  """
  @callback renovate_session!(session :: Ecto.Schema.t()) :: Ecto.Schema.t()
end
