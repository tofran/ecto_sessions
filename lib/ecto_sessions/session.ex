defmodule EctoSessions.Session do
  @doc """
  **Session** is an entity with:
    - `id`: a unique identifier of the session. This should be consired internal.
    - `auth_token`: Random hashed or not token to be used for authorization.
      Ex: session id to be used in a Cookie or X-Api-Token for a REST API.
    - `data`: any data that your aplication needs to store for this session.
      Ex: user id, device name or even ui theme.
    - Any other field defined in `session_fields`. Although most databases allow
      indexes inside a json field, it may be more cumbersome to manage.
  """

  @session_extra_fields [:user_id]

  use Ecto.Schema
  import Ecto.Changeset

  alias EctoSessions.AuthToken

  @primary_key {:id, :binary_id, autogenerate: true}
  schema EctoSessions.Config.get_sessions_table_name() do
    field(:auth_token, :string, null: false)
    field(:plain_auth_token, :string, virtual: true)
    field(:data, :map, null: false)
    field(:expires_at, :utc_datetime_usec, null: true)

    for extra_field <- @session_extra_fields do
      field(extra_field, :string, null: true)
    end

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(session, data) do
    session
    |> cast(%{data: data}, [:data])
    |> validate_required([:data])
    |> put_auth_token()
  end

  @spec put_auth_token(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  def put_auth_token(changeset) do
    case get_field(changeset, :auth_token) do
      nil ->
        {plain_auth_token, hashed_auth_token} = AuthToken.generate()

        put_change(changeset, :auth_token, hashed_auth_token)
        put_change(changeset, :plain_auth_token, plain_auth_token)

      _ ->
        changeset
    end
  end
end
