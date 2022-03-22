defmodule EctoSessions.SessionTest do
  use ExUnit.Case, async: true

  alias EctoSessions.AuthToken
  alias EctoSessions.Config
  alias EctoSessions.Session

  describe "changeset/2" do
    test "success" do
      assert %Ecto.Changeset{
               valid?: true,
               changes: %{
                 expires_at: expires_at,
                 plaintext_auth_token: plaintext_auth_token,
                 hashed_auth_token: hashed_auth_token,
                 user_id: "sample-user-id"
               }
             } =
               %Session{}
               |> Session.changeset(%{
                 user_id: "sample-user-id"
               })

      assert expires_at
             |> DateTime.compare(DateTime.utc_now()) == :gt

      assert String.length(plaintext_auth_token) == Config.get_auth_token_length()

      assert AuthToken.hash(plaintext_auth_token) == hashed_auth_token
    end

    test "success passing data" do
      assert %Ecto.Changeset{
               valid?: true,
               changes: %{
                 expires_at: expires_at,
                 plaintext_auth_token: plaintext_auth_token,
                 hashed_auth_token: hashed_auth_token,
                 user_id: "sample-user-id",
                 data: %{
                   app_theme: "dark",
                   user_agent: "sample-browser"
                 }
               }
             } =
               %Session{}
               |> Session.changeset(%{
                 user_id: "sample-user-id",
                 data: %{
                   app_theme: "dark",
                   user_agent: "sample-browser"
                 }
               })

      assert expires_at
             |> DateTime.compare(DateTime.utc_now()) == :gt

      assert String.length(plaintext_auth_token) == Config.get_auth_token_length()

      assert AuthToken.hash(plaintext_auth_token) == hashed_auth_token
    end

    test "error missing extra field" do
      assert %Ecto.Changeset{
               valid?: false,
               errors: [user_id: {"can't be blank", [validation: :required]}],
               changes: %{
                 expires_at: _,
                 plaintext_auth_token: _,
                 hashed_auth_token: _
               }
             } =
               %Session{}
               |> Session.changeset(%{})
    end

    test "success renovating expiration_time" do
      session = %Session{
        expires_at: ~U[2022-01-22 00:00:00.000000Z],
        inserted_at: ~U[2022-01-01 00:00:00.000000Z],
        updated_at: ~U[2022-01-01 00:00:00.000000Z],
        hashed_auth_token: "sample-hashed-auth-token",
        user_id: "sample-user-id",
        data: %{
          user_agent: "sample-browser"
        }
      }

      assert %Ecto.Changeset{
               valid?: true,
               changes: %{
                 expires_at: new_expires_at
               }
             } = Session.changeset(session)

      assert new_expires_at
             |> DateTime.compare(session.expires_at) == :gt

      assert new_expires_at
             |> DateTime.compare(session.expires_at) == :gt
    end
  end

  describe "get_expires_at/2" do
    test "when current expires_at is nil" do
      assert new_expires_at = Session.get_expires_at(nil)

      assert new_expires_at
             |> DateTime.compare(DateTime.utc_now()) == :gt
    end

    test "when current expires_at is set and refresh is enabled" do
      assert new_expires_at = Session.get_expires_at(~U[2022-01-01 00:00:00.000000Z])

      assert new_expires_at
             |> DateTime.compare(DateTime.utc_now()) == :gt
    end

    # test "when current expires_at is set and refresh is disabled" do
    # TODO: Can only be properlly tested when settings are no longer global
    #   assert new_expires_at = Session.get_expires_at(~U[2022-01-01 00:00:00.000000Z])
    #   assert new_expires_at
    #          |> DateTime.compare(DateTime.utc_now()) == :gt
    # end
  end
end
