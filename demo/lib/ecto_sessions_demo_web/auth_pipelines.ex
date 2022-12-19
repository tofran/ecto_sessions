defmodule EctoSessionsDemoWeb.AuthPipelines do
  use EctoSessionsDemoWeb, :controller

  alias EctoSessionsDemoWeb.Router.Helpers, as: Routes

  alias Plug.Conn
  alias EctoSessionsDemo.Sessions
  alias EctoSessionsDemo.Accounts

  @auth_token_cookie_name "auth_token"
  @auth_token_header_name "x-auth-token"

  def put_browser_session(conn, _opts) do
    Map.get(conn.req_cookies, @auth_token_cookie_name)
    |> put_session(conn)
  end

  def put_api_session(conn, _opts) do
    conn
    |> get_req_header(@auth_token_header_name)
    |> List.first()
    |> put_session(conn)
  end

  def put_session(auth_token, conn) do
    {session, user} = get_session_and_current_user(auth_token)

    conn
    |> Conn.assign(:session, session)
    |> Conn.assign(:user, user)
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

  defp get_session_and_current_user(auth_token) do
    with session when not is_nil(session) <- Sessions.get_session(auth_token: auth_token),
         user when not is_nil(session) <- Accounts.get_user(session.user_id) do
      {session, user}
    else
      _ ->
        {nil, nil}
    end
  end
end
