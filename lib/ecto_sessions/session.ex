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

    - Virtual `is_expired`, true if the session is not expired.

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

      @field_names unquote([:data, :expires_at | extra_field_names])

      @primary_key {:id, :binary_id, autogenerate: true}
      schema unquote(table_name) do
        field(:auth_token, :string, virtual: true, redact: true)
        field(:auth_token_digest, :string, redact: true)
        field(:data, :map, default: %{})
        field(:expires_at, :utc_datetime_usec)
        field(:is_expired, :boolean, virtual: true)

        for {function_name, args} <- unquote(extra_fields) do
          # FIXME Make sure this is more configurable by allowing,
          #  for example, an {Ecto.Schema, :field, args} or
          #  an anonymous *function* like &Ecto.Schema.field/2.

          case function_name do
            :field -> &Ecto.Schema.field/2
            :has_many -> &Ecto.Schema.has_many/3
            :has_one -> &Ecto.Schema.has_one/3
            :belongs_to -> &Ecto.Schema.belongs_to/3
            :many_to_many -> &Ecto.Schema.many_to_many/3
          end
          |> apply(args)
        end

        timestamps(type: :utc_datetime_usec)
      end

      def changeset(%__MODULE__{} = session) do
        changeset(session, %{})
      end

      def changeset(attrs) do
        changeset(%__MODULE__{}, attrs)
      end

      def changeset(session, attrs \\ %{}) do
        session
        |> cast(attrs, @field_names)
        |> put_expires_at()
        |> put_auth_token()
        |> validate_required(@field_names)
      end

      def expire_changeset(session) do
        changeset(
          session,
          %{expires_at: DateTime.utc_now()}
        )
      end

      @spec put_auth_token(Ecto.Changeset.t()) :: Ecto.Changeset.t()
      def put_auth_token(changeset) do
        case get_field(changeset, :auth_token_digest) do
          nil ->
            plaintext_auth_token =
              Config.get_auth_token_length()
              |> AuthToken.generate_token()

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
      def put_expires_at(
            %Ecto.Changeset{
              changes: %{expires_at: expires_at}
            } = changeset
          ) do
        changeset
      end

      def put_expires_at(changeset) do
        expires_at =
          get_field(changeset, :expires_at)
          |> get_new_expires_at()

        put_change(
          changeset,
          :expires_at,
          expires_at
        )
      end

      def get_new_expires_at(_current_expires_at = nil) do
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

      def get_new_expires_at(current_expires_at) do
        case Config.get_extend_session_stale_time() do
          nil ->
            current_expires_at

          extend_session_stale_time ->
            proposed_expired_at =
              DateTime.add(
                DateTime.utc_now(),
                Config.get_session_ttl(),
                :second
              )

            expired_at_threshold =
              DateTime.add(
                current_expires_at,
                extend_session_stale_time,
                :second
              )

            if DateTime.compare(proposed_expired_at, expired_at_threshold) == :gt do
              proposed_expired_at
            else
              current_expires_at
            end
        end
      end
    end
  end
end
