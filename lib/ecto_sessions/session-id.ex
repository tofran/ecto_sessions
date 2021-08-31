defmodule EctoSessions.SessionId do
  @moduledoc """
  This module handles the generation and hasing of session IDs.
  """

  alias EctoSessions.Config

  @doc """
  Generates a random session id given the its length

  ## Examples

      iex> generate(42)
      ajfhwja298eyiajhfa

  """
  @spec generate() :: binary
  def generate() do
    generate(Config.get_session_id_legth())
  end

  @spec generate(non_neg_integer) :: binary
  def generate(length) do
    :crypto.strong_rand_bytes(length)
    |> Base.url_encode64(padding: false)
    |> binary_part(0, length)
  end
end
