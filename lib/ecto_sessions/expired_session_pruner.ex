defmodule EctoSessions.ExpiredSessionPruner do
  @moduledoc """
  `GenServer` implementation to delete expired sessions periodically. Given an `EctoSessions` module
  and periodicity, in milliseconds.

  ## Usage

  - In your project's `application.ex`:

    ```
    def start(_type, _args) do
      children = [
        # ...
        {EctoSessions.ExpiredSessionPruner, {YourSessionsModule, :timer.hours(24)}}
      ]

      opts = [strategy: :one_for_one, name: EctoSessionsDemo.Supervisor]
      Supervisor.start_link(children, opts)
    end
    ```

  - Low level usage with `start_link`:

    ```
    GenServer.start_link(
      EctoSessions.ExpiredSessionPruner,
      {YourSessionsModule, 10_000}
    )
    ```

  Where `YourSessionsModule` is any module that uses `EctoSessions` and the second argument the
  number of milliseconds to 'sleep' between cycles. Ex: `12 * 60 * 60 * 1000` for 12h. Use `:timer`
  for readability.
  """

  use GenServer

  require Logger

  def start_link(args = {module, _sleep_time}) when is_atom(module) do
    GenServer.start_link(
      __MODULE__,
      args,
      name: {:global, Module.concat(__MODULE__, module)}
    )
  end

  def init(state = {module, sleep_time}) when is_atom(module) do
    Logger.debug("Starting session pruner for #{module} (every #{sleep_time}ms)")

    {:ok, prune(state)}
  end

  def handle_info(:prune, state) do
    {:noreply, prune(state)}
  end

  defp prune(state = {module, sleep_time}) do
    delete_count = apply(module, :delete_expired, [])

    Logger.info("Deleted #{delete_count} expired sessions with #{module}")

    Process.send_after(self(), :prune, sleep_time)

    state
  end
end
