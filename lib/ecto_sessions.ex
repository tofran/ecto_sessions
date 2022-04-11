defmodule EctoSessions do
  @default_table_name "sessions"
  @default_extra_fields [{:user_id, :string}]

  @moduledoc """
  This lib implements a set of methods to help you handle the storage and
  access to databse-backend sessions.

  In your application, use `EctoSessions`:

  ```elixir
  defmodule MyApp.Sessions do
    use EctoSessions,
      repo: MyApp.Repo, # required
      prefix: nil, # optional
      table_name: #{inspect(@default_table_name)}, # optional
      extra_fields: #{inspect(@default_extra_fields)} # optional
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
        Session.new(attrs)
        |> @repo.insert(prefix: unquote(prefix))
      end

      def create_session!(attrs \\ %{}) do
        Session.new(attrs)
        |> @repo.insert!(prefix: unquote(prefix))
      end

      def create_auth_token(attrs \\ %{}) do
        %{plaintext_auth_token: plaintext_auth_token} = create_session!(attrs)
        plaintext_auth_token
      end

      def get_expired_sessions_query() do
        from(
          session in Session,
          where:
            not is_nil(session.expires_at) or
              session.expires_at <= ^DateTime.utc_now()
        )
      end

      def get_valid_sessions_query() do
        from(
          session in Session,
          as: :session,
          where:
            is_nil(session.expires_at) or
              session.expires_at > ^DateTime.utc_now()
        )
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
          where: session.auth_token == ^auth_token_digest
        )
      end

      def filter_session_query_by(query, field_name, value) do
        from(
          session in query,
          where: field(session, ^field_name) == ^value
        )
      end

      def get_session(field_name, value) do
        get_valid_sessions_query()
        |> filter_session_query_by(field_name, value)
        |> @repo.one(prefix: unquote(prefix))
      end

      def get_session!(field_name, value) do
        get_valid_sessions_query()
        |> filter_session_query_by(field_name, value)
        |> @repo.one!(prefix: unquote(prefix))
      end

      def renovate_session(session) do
        Session.changeset(session)
        |> @repo.update!(prefix: unquote(prefix))
      end
    end
  end

  @doc """
  Creates a session. `attrs` is a map that contains `EctoSessions.Session` attributes,
  where the keys are atoms.

  Uses `Ecto.Repo.insert/2`

  ## Examples

      iex> create_session(%{user_id: "1234", data: %{device_name: "Samle Browser"}})
      %Session{
        user_id: "1234",
        data: %{
          device_name: "Sample Browser",
          plaintext_auth_token: "plaintext-auth-token"
          auth_token: "hashed-token"
        }
      }
  """
  @callback create_session(attrs :: map) :: Ecto.Schema.t()

  @doc """
  Same as `create_session/1` but using `Ecto.Repo.insert!/2`.
  """
  @callback create_session!(attrs :: map) :: Ecto.Schema.t()

  @doc """
  Creates a session using `create_session!/1` returing only the plaintext auth token.

  ## Examples

      iex> create_session(%{user_id: "1234", data: %{device_name: "Samle Browser"}})
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
