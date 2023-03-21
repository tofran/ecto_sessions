defmodule EctoSessionsDemo.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      EctoSessionsDemo.Repo,
      # Start the Telemetry supervisor
      EctoSessionsDemoWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: EctoSessionsDemo.PubSub},
      # Start the Endpoint (http/https)
      EctoSessionsDemoWeb.Endpoint,
      # Start a worker by calling: EctoSessionsDemo.Worker.start_link(arg)
      {EctoSessions.ExpiredSessionPruner, {EctoSessionsDemo.Sessions, :timer.hours(24)}}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: EctoSessionsDemo.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    EctoSessionsDemoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
