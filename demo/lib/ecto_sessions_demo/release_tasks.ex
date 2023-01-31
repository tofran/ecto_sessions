defmodule EctoSessionsDemo.ReleaseTasks do
  @app :ecto_sessions_demo

  def migrate do
    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos do
    Application.load(@app)
    Application.ensure_all_started(:ssl)
    Application.fetch_env!(@app, :ecto_repos)
  end
end
