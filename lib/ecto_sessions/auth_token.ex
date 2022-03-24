defmodule EctoSessions.AuthToken do
  @moduledoc """
  This module handles the generation and hashing of auth tokens.
  """

  alias EctoSessions.Config

  @doc """
  Generates a random auth token.
  `generate/0` will use the configuration parameters, see `EctoSessions.Config` for more informaton.

  `length` is a psitive integer that will dictate the length of the token.
  For authentication purposes it should not be lower than 32. The entropy can be calculated as `length^64`.

  ## Examples

      iex> generate()
      4GukTw2aOy77qeC-TnUabqNx_-KJK65SlkS2XiQXKORlk9GxKKjvHCO_8ZhXW0Tw

      iex> generate(32)
      mwIzAAAIWfTRsaAOTQAUd0-0UsiX-yfM

  """
  @spec generate() :: binary
  def generate() do
    Config.get_auth_token_length()
    |> generate()
  end

  @spec generate(non_neg_integer) :: binary
  def generate(length) do
    :crypto.strong_rand_bytes(length)
    |> Base.url_encode64(padding: false)
    |> binary_part(0, length)
  end

  @doc """
  Creates a new auth_token with `generate/0` and hashes it with `hash/0`.
  Returning a tuple `{plaintext_auth_token, auth_token}`.
  Where `auth_token` might be hashed according to the configuration.
  """
  def get_auth_token do
    plaintext_auth_token = generate()

    {plaintext_auth_token, hash(plaintext_auth_token)}
  end

  def hash(auth_token) when is_nil(auth_token) or auth_token == "",
    do: raise("Aborted attempt to hash token: #{inspect(auth_token)}")

  def hash(auth_token) do
    Config.get_hashing_algorithm()
    |> hash(auth_token)
  end

  def hash(_hashing_algorithm = nil, auth_token), do: auth_token

  def hash(hashing_algorithm, auth_token) do
    salted_token = add_salt(auth_token)

    hashing_algorithm
    |> :crypto.hash(salted_token)
    |> Base.encode16(case: :lower)
  end

  def add_salt(auth_token), do: add_salt(auth_token, Config.get_hashing_secret_salt())

  def add_salt(auth_token, _salt = nil), do: auth_token

  def add_salt(auth_token, salt), do: "#{salt}#{auth_token}"
end
