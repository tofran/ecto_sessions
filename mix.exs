defmodule EctoSessions.MixProject do
  use Mix.Project

  def project do
    [
      app: :ecto_sessions,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [
        :logger,
        :crypto
      ]
    ]
  end

  defp deps do
    [
      {:ecto, "~> 3.6"},
      {:ecto_sql, "~> 3.6"}
    ]
  end
end
