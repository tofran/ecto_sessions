defmodule EctoSessionsDemoWeb.PageController do
  use EctoSessionsDemoWeb, :controller

  alias Plug.Conn
  alias EctoSessionsDemoWeb.Router.Helpers, as: Routes
  alias EctoSessionsDemo.Accounts
  alias EctoSessionsDemo.Sessions

  @cookie_key "auth_token"
  @cookie_max_age 2 * 365 * 24 * 60 * 60

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def signup(conn, _params) do
    {:ok, user} = Accounts.create_user()

    conn
    |> put_flash(:info, "User '#{user.id}' was created, use it to login.")
    |> redirect(to: Routes.page_path(conn, :index))
  end

  def login(conn, params) do
    Map.get(params, "user_id")
    |> Accounts.get_user()
    |> case do
      nil ->
        conn
        |> put_flash(
          :error,
          "Invalid user id. Please signup first (note: old users might be deleted sporadically, this is a demo project)"
        )
        |> redirect(to: Routes.page_path(conn, :index))

      user ->
        {:ok, session} = EctoSessionsDemo.Sessions.create_session(%{user_id: user.id})

        conn
        |> put_flash(
          :info,
          "You are now logged in as #{user.id}"
        )
        |> Conn.put_resp_cookie(
          @cookie_key,
          session.auth_token,
          max_age: @cookie_max_age
        )
        |> redirect(to: Routes.page_path(conn, :account))
    end
  end

  def sign_out(conn, _) do
    conn
    |> Conn.delete_resp_cookie(@cookie_key)
    |> redirect(to: Routes.page_path(conn, :index))
  end

  def account(%{assigns: %{user: current_user}} = conn, _) do
    sessions = Sessions.list_all_sessions(user_id: current_user.id)

    render(
      conn,
      "account.html",
      sessions: sessions
    )
  end
end
