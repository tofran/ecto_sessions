defmodule EctoSessionsDemoWeb.PageController do
  use EctoSessionsDemoWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
