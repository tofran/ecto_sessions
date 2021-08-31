defmodule EctoSessions.Session do
  use Ecto.Schema
  import Ecto.Changeset

  alias EctoSessions.SessionId

  @primary_key {:id, :string, []}
  schema "sessions" do
    field(:properties, :map, null: false)

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(session, properties) do
    session
    |> cast(%{properties: properties}, [:properties])
    |> validate_required([:properties])
    |> put_id
  end

  @spec put_id(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  def put_id(changeset) do
    case get_field(changeset, :id) do
      nil ->
        put_change(changeset, :id, SessionId.generate())

      _ ->
        changeset
    end
  end
end
