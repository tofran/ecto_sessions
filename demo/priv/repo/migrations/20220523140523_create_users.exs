defmodule EctoSessionsDemo.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :string, primary_key: true

      timestamps(type: :utc_datetime_usec)
    end
  end
end
