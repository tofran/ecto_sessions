defmodule EctoSessionsDemo.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {
    :id,
    :string,
    autogenerate: {Nanoid, :generate, [6, "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"]}
  }
  @foreign_key_type :string
  schema "users" do
    timestamps(type: :utc_datetime_usec)
  end

  def changeset() do
    changeset(%__MODULE__{}, %{})
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [])
    |> validate_required([])
    |> unique_constraint(:id, name: "users_pkey")
  end
end
