defmodule EctoSessions.MixProject do
  use Mix.Project

  @source_url "https://github.com/tofran/ecto_sessions"

  def project do
    [
      app: :ecto_sessions,
      version: "0.0.1-development",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      source_url: @source_url,
      deps: deps(),
      package: package(),
      docs: [
        main: "readme",
        source_url: @source_url,
        extras: [
          "README.md",
          "CHANGELOG.md"
        ]
      ],
      description:
        "Helps you easily and securely manage database backed sessions an ecto project.",
      name: "Ecto Sessions"
    ]
  end

  defp package do
    [
      maintainers: ["tofran"],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url}
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
      {:ecto_sql, "~> 3.6"},
      {:ex_doc, "~> 0.28", only: :dev, runtime: false}
    ]
  end
end
