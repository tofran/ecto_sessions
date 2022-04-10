defmodule EctoSessions.SessionTest do
  use ExUnit.Case, async: true

  alias EctoSessions.AuthToken

  @otp_app :undefined

  defmodule SampleRepo do
    use Ecto.Repo,
      otp_app: :sample_app,
      adapter: Ecto.Adapters.Postgres
  end

  defmodule DefaultConfigEctoSessions do
    use EctoSessions,
      otp_app: :sample_app,
      repo: SampleRepo
  end

  describe "new/1 using defaults" do
    alias DefaultConfigEctoSessions.Session

    test "success" do
      assert %Ecto.Changeset{
               valid?: true,
               changes: %{
                 expires_at: expires_at,
                 plaintext_auth_token: plaintext_auth_token,
                 auth_token: auth_token,
                 user_id: "sample-user-id"
               }
             } =
               Session.new(%{
                 user_id: "sample-user-id"
               })

      assert DateTime.compare(expires_at, DateTime.utc_now()) == :gt

      assert plaintext_auth_token =~ ~r/^[A-z0-9\_\-]{64}$/

      assert AuthToken.get_digest(plaintext_auth_token, :sha256, nil) == auth_token
    end

    test "success passing data" do
      assert %Ecto.Changeset{
               valid?: true,
               changes: %{
                 expires_at: expires_at,
                 plaintext_auth_token: plaintext_auth_token,
                 auth_token: auth_token,
                 user_id: "sample-user-id",
                 data: %{
                   app_theme: "dark",
                   user_agent: "sample-browser"
                 }
               }
             } =
               Session.new(%{
                 user_id: "sample-user-id",
                 data: %{
                   app_theme: "dark",
                   user_agent: "sample-browser"
                 }
               })

      assert DateTime.compare(expires_at, DateTime.utc_now()) == :gt

      assert plaintext_auth_token =~ ~r/^[A-z0-9\_\-]{64}$/

      assert AuthToken.get_digest(plaintext_auth_token, :sha256, nil) == auth_token
    end

    test "error missing required extra field" do
      assert %Ecto.Changeset{
               valid?: false,
               errors: [user_id: {"can't be blank", [validation: :required]}],
               changes: %{
                 expires_at: _,
                 plaintext_auth_token: _,
                 auth_token: _
               }
             } = Session.new(%{})
    end
  end

  describe "changeset/2 using custom configuration" do
    defmodule CustomConfigEctoSessions do
      use EctoSessions,
        otp_app: :sample_app,
        repo: SampleRepo
    end

    alias CustomConfigEctoSessions.Session

    setup do
      Application.put_env(
        @otp_app,
        CustomConfigEctoSessions,
        auth_token_length: 128,
        hashing_algorithm: :sha512,
        secret_salt: "sample-secret-salt",
        session_ttl: nil
      )
    end

    test "success" do
      assert %Ecto.Changeset{
               valid?: true,
               changes:
                 %{
                   plaintext_auth_token: plaintext_auth_token,
                   auth_token: auth_token,
                   user_id: "sample-user-id"
                 } = changes
             } =
               Session.new(%{
                 user_id: "sample-user-id"
               })

      assert :expires_at not in changes

      assert plaintext_auth_token =~ ~r/^[A-z0-9\_\-]{128}$/

      assert auth_token ==
               AuthToken.get_digest(
                 plaintext_auth_token,
                 :sha512,
                 "sample-secret-salt"
               )
    end

    test "success passing data" do
      assert %Ecto.Changeset{
               valid?: true,
               changes:
                 %{
                   plaintext_auth_token: plaintext_auth_token,
                   auth_token: auth_token,
                   user_id: "sample-user-id",
                   data: %{
                     app_theme: "dark",
                     user_agent: "sample-browser"
                   }
                 } = changes
             } =
               Session.new(%{
                 user_id: "sample-user-id",
                 data: %{
                   app_theme: "dark",
                   user_agent: "sample-browser"
                 }
               })

      assert :expires_at not in changes

      assert plaintext_auth_token =~ ~r/^[A-z0-9\_\-]{128}$/

      assert auth_token ==
               AuthToken.get_digest(
                 plaintext_auth_token,
                 :sha512,
                 "sample-secret-salt"
               )
    end

    test "error missing required extra field" do
      assert %Ecto.Changeset{
               valid?: false,
               errors: [user_id: {"can't be blank", [validation: :required]}],
               changes: %{
                 plaintext_auth_token: _,
                 auth_token: _
               }
             } = Session.new(%{})
    end
  end

  describe "changeset/2 using defaults" do
    alias DefaultConfigEctoSessions.Session

    test "success renovating expiration_time" do
      session = %Session{
        expires_at: ~U[2022-01-22 00:00:00.000000Z],
        inserted_at: ~U[2022-01-01 00:00:00.000000Z],
        updated_at: ~U[2022-01-01 00:00:00.000000Z],
        auth_token: "sample-hashed-auth-token",
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

  describe "get_expires_at/2 using default config" do
    alias DefaultConfigEctoSessions.Session

    test "when current expires_at is nil" do
      assert new_expires_at = Session.get_expires_at(nil)

      assert DateTime.compare(new_expires_at, DateTime.utc_now()) == :gt
    end

    test "when current expires_at is set (refresh is enabled)" do
      assert new_expires_at = Session.get_expires_at(~U[2022-01-01 00:00:00.000000Z])

      assert DateTime.compare(new_expires_at, DateTime.utc_now()) == :gt
    end
  end

  describe "get_expires_at/2 with refresh_session_ttl disabled" do
    defmodule RefreshingDisabledEctoSessions do
      use EctoSessions,
        otp_app: :sample_app,
        repo: SampleRepo
    end

    alias RefreshingDisabledEctoSessions.Session

    setup do
      Application.put_env(
        @otp_app,
        RefreshingDisabledEctoSessions,
        refresh_session_ttl: nil
      )
    end

    test "when current expires_at is nil" do
      assert new_expires_at = Session.get_expires_at(nil)

      assert DateTime.compare(new_expires_at, DateTime.utc_now()) == :gt
    end

    test "when current expires_at is set" do
      initial_expires_at = ~U[2022-01-01 00:00:00.000000Z]

      assert initial_expires_at == Session.get_expires_at(initial_expires_at)
    end
  end

  describe "get_expires_at/2 with session_ttl disabled" do
    defmodule SessionTTLDisabledEctoSessions do
      use EctoSessions,
        otp_app: :sample_app,
        repo: SampleRepo
    end

    alias SessionTTLDisabledEctoSessions.Session

    setup do
      Application.put_env(
        @otp_app,
        SessionTTLDisabledEctoSessions,
        session_ttl: nil
      )
    end

    test "when current expires_at is nil" do
      assert Session.get_expires_at(nil) == nil
    end
  end
end
