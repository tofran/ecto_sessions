defmodule EctoSessions.Session do
  @doc """
  **Session** is an Ecto schema with:

    - `id`: a unique identifier of the session. This should be used by your application
      for internal purposes (ex: references, logs, etc), and not exposed to the end user.

    - `auth_token_digest`: Random hashed token (or not, according to the configuration).

    - `auth_token`: A virtual field available ony upon Session creation.
      It contains the plaintext version of the `auth_token_digest`.

    - `data`: any data that your application needs to store for this session.
      Ex: user id, device name or even ui theme.

    - Any other field defined under `extra_fields`.
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
        fn {_function, [field_name | _]} ->
          field_name
        end
      )

    quote do
      use Ecto.Schema
      import Ecto.Changeset

      alias unquote(config_module)

      @field_names unquote([:data | extra_field_names])

      @primary_key {:id, :binary_id, autogenerate: true}
      schema unquote(table_name) do
        field(:auth_token, :string, virtual: true, redact: true)
        field(:auth_token_digest, :string)
        field(:data, :map, default: %{})
        field(:expires_at, :utc_datetime_usec)
        field(:is_valid, :boolean, virtual: true)

        for {_function, args} <- unquote(extra_fields) do
          # FIXME function being ignored: in the next line we should call it instead of field
          apply(&Ecto.Schema.field/2, args)
        end

        timestamps(type: :utc_datetime_usec)
      end

      def changeset(attrs), do: changeset(%__MODULE__{}, attrs)

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
            |> put_change(:auth_token, plaintext_auth_token)
            |> put_change(:auth_token_digest, auth_token_digest)

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
end
