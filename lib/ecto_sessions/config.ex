defmodule EctoSessions.Config do
  @moduledoc """
  ecto_sessions configuration
  """

  @default_session_id_length 256

  @spec get_session_id_legth :: :error | integer
  def get_session_id_legth() do
    {length, _} =
      Application.get_env(
        :ecto_sessions,
        :session_id_length,
        @default_session_id_length
      )
      |> Integer.parse()

    length
  end

  @spec generate(non_neg_integer) :: binary
  def generate(length) do
    :crypto.strong_rand_bytes(length)
    |> Base.url_encode64(padding: false)
    |> binary_part(0, length)
  end
end
