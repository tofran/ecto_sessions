defmodule EctoSessions.AuthToken do
  @moduledoc """
  This module handles the generation and hashing of auth tokens.
  Auth token is a cryptographically random string used for Authorization.
  """

  @doc """
  Generates a cryptographically random auth token.

  `length` is a positive integer that will dictate the length of the token.
  For authentication purposes it should not be lower than 32.

  The token will contain characters from `A-z`, `0-9` plus `_` and `-`.
  The  number of unique possible strings (entropy) can be calculated as `64^length`.
  """
  @spec generate_token(non_neg_integer) :: binary

  def generate_token(length) when length < 16 do
    raise "The auth token length must be at least 16 (128 bits)"
  end

  def generate_token(length) do
    :crypto.strong_rand_bytes(length)
    |> Base.url_encode64(padding: false)
    |> binary_part(0, length)
  end

  @doc """
  Given an auth token, hashes it and salts it. Hashing and salting can be disabling passng
  `nil`. But salting only works when hashing is enabled.

  See `hash` ad `add_salt` for further reference.

  ## Examples

      iex> get_digest("sample", nil, nil)
      "sample"

      iex> get_digest("sample", :sha256, nil)
      "af2bdbe1aa9b6ec1e2ade1d694f41fc71a831d0268e9891562113d8a62add1bf"

      iex> get_digest("sample", :sha256, "your-secret-salt")
      "709a5d6cba7d3162a1035b0a9cd13064ee4cbe4587cbcc4e378d831e728310c7"

  """
  @spec get_digest(binary, atom | nil, binary | nil) :: binary

  def get_digest(_plaintext_token, _hashing_algorithm = nil, secret_salt)
      when not is_nil(secret_salt) do
    raise "Cannot salt a token that is not hashed. " <>
            "When hashing_algorithm is nil secret_salt must also be nil."
  end

  def get_digest(plaintext_token, hashing_algorithm, secret_salt) do
    plaintext_token
    |> salt(secret_salt)
    |> hash(hashing_algorithm)
  end

  # Creates a new auth_token with `generate/0` and hashes it with `hash/0`.
  # Returning a tuple `{plaintext_auth_token, auth_token}`.
  # Where `auth_token` might be hashed according to the configuration.

  @doc """
  Hashes a token with the provided hashing algorithm. Uses erlang's `:cripto` module.

  `hashing_algorithm` can be:

    - `:sha`
    - `:sha224`
    - `:sha256`
    - `:sha384`
    - `:sha512`
    - `:sha3_224`
    - `:sha3_256`
    - `:sha3_384`
    - `:sha3_512`
    - `:blake2b`
    - `:blake2s`
    - `:ripemd160`
    - `nil` to not hash, and store tokens in plaintext - not recommended;

  See [erlang's crypto's `hash_algorithm()`](https://www.erlang.org/doc/man/crypto.html#type-hash_algorithm)
  for more information


  ## Examples

      iex> hash("sample", nil)
      "sample"

      iex> hash("sample", :sha256)
      "af2bdbe1aa9b6ec1e2ade1d694f41fc71a831d0268e9891562113d8a62add1bf"

      iex> hash("sample", :sha256)
      "af2bdbe1aa9b6ec1e2ade1d694f41fc71a831d0268e9891562113d8a62add1bf"

      iex> hash("sample", :sha512)
      "39a5e04aaff7455d9850c605364f514c11324ce64016960d23d5dc57d3ffd8f4" <>
        "9a739468ab8049bf18eef820cdb1ad6c9015f838556bc7fad4138b23fdf986c7"

      iex> hash("sample", :sha3_256)
      "f68f564e181663381ef67ae5849d3dd1d0f1044cf468d0a0b7875e4ff121906f"

      iex> hash("sample", :nil)
      "sample"

  """
  @spec hash(binary, atom) :: any
  def hash(auth_token, _hashing_algorithm = nil), do: auth_token

  def hash(auth_token, _hashing_algorithm) when is_nil(auth_token) or auth_token == "" do
    raise("Aborted attempt to hash empty token.")
  end

  def hash(auth_token, hashing_algorithm) do
    hashing_algorithm
    |> :crypto.hash(auth_token)
    |> Base.encode16(case: :lower)
  end

  @doc """
  Appends a global, secret salt to the given token. Sometimes referred as *pepper*.

  ## Examples

      iex> salt("sample", nil)
      "sample"

      iex> salt("sample", "your-secret-salt")
      "your-secret-saltsample"

  """
  @spec salt(binary, binary) :: binary
  def salt(auth_token, _salt = nil), do: auth_token

  def salt(auth_token, salt), do: "#{salt}#{auth_token}"
end
