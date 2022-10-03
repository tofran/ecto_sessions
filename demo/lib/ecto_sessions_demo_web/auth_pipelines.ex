defmodule EctoSessionsDemoWeb.AuthPipelines do
  use EctoSessionsDemoWeb, :controller

  alias EctoSessionsDemoWeb.Router.Helpers, as: Routes

  alias Plug.Conn
  alias EctoSessionsDemo.Sessions
  alias EctoSessionsDemo.Accounts

  @auth_token_cookie_key "auth_token"

  def put_session(conn, _opts) do
    auth_token = conn.req_cookies |> Map.get(@auth_token_cookie_key)

    with session when not is_nil(session) <- Sessions.get_session(:auth_token, auth_token),
         user when not is_nil(session) <- Accounts.get_user(session.user_id) do
      conn
      |> Conn.assign(:session, session)
      |> Conn.assign(:user, user)
    else
      _ -> conn
    end
  end

  def require_authenticated(
        %{
          assigns: %{user: user, session: session}
        } = conn,
        _opts
      )
      when session != nil and user != nil do
    conn
  end

  def require_authenticated(conn, _opts) do
    conn
    |> redirect(to: Routes.page_path(conn, :index))
    |> Conn.halt()
  end
end
