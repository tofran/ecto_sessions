defmodule EctoSessions.Session do
  @doc """
  **Session** is an entity with:

    - `id`: a unique identifier of the session. This should be used by your application
      for internal purposes (ex: references, logs, etc), and not exposed to the user.

    - `auth_token`: Random hashed token (or not, acoording to the configuration).

    - `plaintext_auth_token`: A virtual field available ony upon Session creation.
      It contains an unhashed, plaintext, version of the `auth_token`.

    - `data`: any data that your aplication needs to store for this session.
      Ex: user id, device name or even ui theme.

    - Any other field defined under `exra_fields`.
  """

  defmacro __using__(opts) do
    table_name = Keyword.fetch!(opts, :table_name)
    extra_fields = Keyword.fetch!(opts, :extra_fields)

    extra_field_names =
      Enum.map(
        extra_fields,
        fn {field_name, _field_type} -> field_name end
      )

    quote do
      use Ecto.Schema
      import Ecto.Changeset

      alias EctoSessions.AuthToken
      alias EctoSessions.Config

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

      @doc false
      def changeset(session, attrs \\ %{}) do
        field_names = unquote([:data | extra_field_names])

        session
        |> cast(attrs, field_names)
        |> validate_required(field_names)
        |> put_expires_at()
        |> put_auth_token()
      end

      @spec put_auth_token(Ecto.Changeset.t()) :: Ecto.Changeset.t()
      def put_auth_token(changeset) do
        case get_field(changeset, :auth_token) do
          nil ->
            {plaintext_auth_token, auth_token} = AuthToken.get_auth_token()

            changeset
            |> put_change(:auth_token, auth_token)
            |> put_change(:plaintext_auth_token, plaintext_auth_token)

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
        DateTime.add(
          DateTime.utc_now(),
          Config.get_session_ttl(),
          :second
        )
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
