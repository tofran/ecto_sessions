defmodule EctoSessionsDemo.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `EctoSessionsDemo.Accounts` context.
  """

  @doc """
  Generate a user.
  """
  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{})
      |> EctoSessionsDemo.Accounts.create_user()

    user
  end
end
