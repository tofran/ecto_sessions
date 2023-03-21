defmodule EctoSessionsDemoWeb.PageController do
  use EctoSessionsDemoWeb, :controller

  alias Plug.Conn
  alias EctoSessionsDemoWeb.Router.Helpers, as: Routes
  alias EctoSessionsDemo.Accounts
  alias EctoSessionsDemo.Sessions

  @auth_token_cookie_name "auth_token"
  @last_user_id_cookie_name "last_user_id"
  @cookie_max_age 2 * 365 * 24 * 60 * 60

  def index(conn, _params) do
    render(
      conn,
      "index.html",
      last_user_id: Map.get(conn.req_cookies, @last_user_id_cookie_name)
    )
  end

  defp create_session(conn, user) do
    {:ok, session} =
      EctoSessionsDemo.Sessions.create_session(%{
        user_id: user.id,
        data: %{
          user_agent:
            conn
            |> get_req_header("user-agent")
            |> List.first(),
          ip:
            :inet.ntoa(conn.remote_ip)
            |> to_string()
        }
      })

    conn
    |> put_flash(
      :info,
      "You are now logged in as #{user.id}."
    )
    |> Conn.put_resp_cookie(
      @auth_token_cookie_name,
      session.auth_token,
      max_age: @cookie_max_age
    )
    |> Conn.put_resp_cookie(
      @last_user_id_cookie_name,
      user.id,
      max_age: @cookie_max_age
    )
    |> redirect(to: Routes.page_path(conn, :account))
  end

  def signup(conn, _params) do
    {:ok, user} = Accounts.create_user()

    create_session(conn, user)
  end

  def login(conn, params) do
    Map.get(params, "user_id")
    |> Accounts.get_user()
    |> case do
      nil ->
        conn
        |> put_flash(
          :error,
          "Invalid user id. Please signup first (note: data might be deleted sporadically, this is a demo project)"
        )
        |> redirect(to: Routes.page_path(conn, :index))

      user ->
        create_session(conn, user)
    end
  end

  def expire_session(
        conn = %{
          assigns: %{session: current_session, user: user}
        },
        %{"session_id" => session_id}
      )
      when current_session.id != session_id do
    case Sessions.get_session(id: session_id, user_id: user.id) do
      nil ->
        conn
        |> put_flash(
          :error,
          "Session #{session_id} not found"
        )
        |> redirect(to: Routes.page_path(conn, :account))

      session ->
        EctoSessionsDemo.Sessions.expire_session!(session)

        conn
        |> put_flash(
          :info,
          "Session #{session_id} expired"
        )
        |> redirect(to: Routes.page_path(conn, :account))
    end
  end

  def expire_session(
        conn = %{
          assigns: %{session: session, user: user}
        },
        _
      ) do
    EctoSessionsDemo.Sessions.expire_session!(session)

    conn
    |> Conn.delete_resp_cookie(@auth_token_cookie_name)
    |> put_flash(
      :info,
      "Your session has expired, use the user id '#{user.id}' to login back again."
    )
    |> redirect(to: Routes.page_path(conn, :index))
  end

  def sign_out(
        conn = %{
          assigns: %{session: current_session, user: user}
        },
        %{"session_id" => session_id}
      )
      when current_session.id != session_id do
    case Sessions.get_session(
           id: session_id,
           user_id: user.id,
           status: :all
         ) do
      nil ->
        conn
        |> put_flash(
          :error,
          "Session #{session_id} not found"
        )
        |> redirect(to: Routes.page_path(conn, :account))

      session ->
        EctoSessionsDemo.Sessions.delete_session!(session)

        conn
        |> put_flash(
          :info,
          "Session '#{session_id}' deleted."
        )
        |> redirect(to: Routes.page_path(conn, :account))
    end
  end

  def sign_out(
        conn = %{
          assigns: %{session: session, user: user}
        },
        _params
      ) do
    EctoSessionsDemo.Sessions.delete_session!(session)

    conn
    |> Conn.delete_resp_cookie(@auth_token_cookie_name)
    |> put_flash(
      :info,
      "You have been logged out, use the user id '#{user.id}' to login back again."
    )
    |> redirect(to: Routes.page_path(conn, :index))
  end

  def sign_out(conn, _) do
    conn
    |> Conn.delete_resp_cookie(@auth_token_cookie_name)
    |> redirect(to: Routes.page_path(conn, :index))
  end

  def sign_out_all(
        conn = %{
          assigns: %{session: _session, user: user}
        },
        _params
      ) do
    EctoSessionsDemo.Sessions.get_sessions_query([user_id: user.id], delete_query: true)
    |> EctoSessionsDemo.Repo.delete_all()

    conn
    |> Conn.delete_resp_cookie(@auth_token_cookie_name)
    |> put_flash(
      :info,
      "You have been logged out, use the user id '#{user.id}' to login back again."
    )
    |> redirect(to: Routes.page_path(conn, :index))
  end

  def account(%{assigns: %{user: current_user}} = conn, _) do
    sessions =
      Sessions.list_sessions(
        user_id: current_user.id,
        status: :all
      )

    render(
      conn,
      "account.html",
      sessions: sessions,
      auth_token: Map.get(conn.req_cookies, @auth_token_cookie_name)
    )
  end

  def stats(conn, _) do
    render(
      conn,
      "stats.html",
      total_session_count: Sessions.count(status: :all),
      active_session_count: Sessions.count(status: :valid),
      expired_session_count: Sessions.count(status: :expired)
    )
  end
end
