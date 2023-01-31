defmodule EctoSessionsDemoWeb.Router do
  use EctoSessionsDemoWeb, :router

  import EctoSessionsDemoWeb.AuthPipelines

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, {EctoSessionsDemoWeb.LayoutView, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(:put_browser_session)
  end

  pipeline :api do
    plug(:accepts, ["json"])
    plug(:put_api_session)
  end

  scope "/", EctoSessionsDemoWeb do
    pipe_through(:browser)

    get("/", PageController, :index)
    post("/login", PageController, :login)
    post("/signup", PageController, :signup)
  end

  scope "/", EctoSessionsDemoWeb do
    pipe_through([:browser, :require_authenticated])

    get("/account", PageController, :account)
    post("/sign-out", PageController, :sign_out)
    post("/sign-out-all", PageController, :sign_out_all)
    post("/expire-session", PageController, :expire_session)
  end

  scope "/api", EctoSessionsDemoWeb do
    pipe_through([:api])

    get("/me", ApiController, :me)
  end

  # Other scopes may use custom stacks.
  # scope "/api", EctoSessionsDemoWeb do
  #   pipe_through :api
  # end
end
