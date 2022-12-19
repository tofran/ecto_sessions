defmodule EctoSessionsDemoWeb.ApiController do
  use EctoSessionsDemoWeb, :controller

  def me(
        conn = %{
          assigns: %{session: session, user: user}
        },
        _opts
      )
      when not is_nil(session) and not is_nil(user) do
    conn
    |> json(%{
      is_logged_in: not is_nil(session),
      user: %{
        id: user.id,
        inserted_at: user.inserted_at,
        updated_at: user.updated_at
      },
      session: %{
        session: session.id,
        expires_at: session.expires_at,
        inserted_at: user.inserted_at,
        updated_at: user.updated_at
      }
    })
  end

  def me(conn, _opts) do
    json(
      conn,
      %{
        is_logged_in: false
      }
    )
  end
end
