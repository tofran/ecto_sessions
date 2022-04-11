defmodule EctoSessions.Session do
  @doc """
  **Session** is an Ecto schema with:

    - `id`: a unique identifier of the session. This should be used by your application
      for internal purposes (ex: references, logs, etc), and not exposed to the end user.

    - `auth_token`: Random hashed token (or not, acoording to the configuration).

    - `plaintext_auth_token`: A virtual field available ony upon Session creation.
      It contains an unhashed, plaintext, version of the `auth_token`.

    - `data`: any data that your aplication needs to store for this session.
      Ex: user id, device name or even ui theme.

    - Any other field defined under `exra_fields`.
      Ex: `[ {:user_id, :string}, {:role, :string} ]`

  By default if you have used `EctoSessions` in your project, import it with:
  `alias MyApp.EctoSessions.Session`

  """

  alias EctoSessions.AuthToken

  defmacro __using__(opts) do
    table_name = Keyword.fetch!(opts, :table_name)
    extra_fields = Keyword.fetch!(opts, :extra_fields)
    config_module = Keyword.fetch!(opts, :config_module)

    extra_field_names =
      Enum.map(
        extra_fields,
        fn {field_name, _field_type} -> field_name end
      )

    quote do
      use Ecto.Schema
      import Ecto.Changeset

      alias unquote(config_module)

      @field_names unquote([:data | extra_field_names])

      @primary_key {:id, :binary_id, autogenerate: true}
      schema unquote(table_name) do
        field(:auth_token, :string, null: false)
        field(:plaintext_auth_token, :string, virtual: true)
        field(:data, :map, null: false, default: %{})
        field(:expires_at, :utc_datetime_usec, null: true)

        for {field_name, field_type} <- unquote(extra_fields) do
          field(field_name, field_type, null: false)
        end

        timestamps(type: :utc_datetime_usec)
      end

      def new(attrs), do: changeset(%__MODULE__{}, attrs)

      @doc false
      def changeset(session, attrs \\ %{}) do
        session
        |> cast(attrs, @field_names)
        |> validate_required(@field_names)
        |> put_expires_at()
        |> put_auth_token()
      end

      @spec put_auth_token(Ecto.Changeset.t()) :: Ecto.Changeset.t()
      def put_auth_token(changeset) do
        case get_field(changeset, :auth_token) do
          nil ->
            plaintext_auth_token = AuthToken.generate_token(Config.get_auth_token_length())

            auth_token_digest =
              AuthToken.get_digest(
                plaintext_auth_token,
                Config.get_hashing_algorithm(),
                Config.get_secret_salt()
              )

            changeset
            |> put_change(:plaintext_auth_token, plaintext_auth_token)
            |> put_change(:auth_token, auth_token_digest)

          _ ->
            changeset
        end
      end

      @spec put_expires_at(Ecto.Changeset.t()) :: Ecto.Changeset.t()
      def put_expires_at(changeset) do
        expires_at =
          get_field(changeset, :expires_at)
          |> get_expires_at()

        put_change(
          changeset,
          :expires_at,
          expires_at
        )
      end

      def get_expires_at(_current_expires_at = nil) do
        case Config.get_session_ttl() do
          nil ->
            nil

          session_ttl ->
            DateTime.add(
              DateTime.utc_now(),
              session_ttl,
              :second
            )
        end
      end

      def get_expires_at(current_expires_at) do
        case Config.get_refresh_session_ttl() do
          nil ->
            current_expires_at

          refresh_session_ttl ->
            DateTime.add(
              DateTime.utc_now(),
              refresh_session_ttl,
              :second
            )
        end
      end
    end
  end

  @doc """
  Retuns a new session without sensitive data: `plaintext_auth_token` is dropped.
  """
  def clear_sensitive_data(session) do
    Map.drop(session, [:plaintext_auth_token])
  end
end
