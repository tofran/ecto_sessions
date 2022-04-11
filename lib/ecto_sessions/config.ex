defmodule EctoSessions.Config do
  @moduledoc """
  This module handles ecto_sessions runtime configuration.

  In your `runtime.exs`/`config.exs`:

  ```
  config :your_app, MyApp.EctoSessions,
    auth_token_length: 128,
    hashing_algorithm: :sha512,
    secret_salt: "my-unique-secret",
    session_ttl: 60 * 60 * 24,
    refresh_session_ttl: 60 * 60 * 12
  ```

  ### `auth_token_length`

  Returns the length of the session auth token.
  Defaults to `64`. Can be changed at any time, applies for new sessions only.

  ### `hashing_algorithm`

  Returns the hashing algorithm to use. Can be one of the followng:

    - `:sha256` the default;
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
    - `nil` to not hash, and store tokens in plaintext;

  See [erlang's crypto `hash_algorithm()`](https://www.erlang.org/doc/man/crypto.html#type-hash_algorithm)
  for more information.

  ### hashing_algorithm

  Optional *secret salt*, commonly known as *pepper* to be added to the
  auth token before hashing.
  **Once changed, invalidates all sessions, as lookup is no longer possible.**
  Can only be set if `hashing_algorithm` is not `nil`.
  Set to `nil` to not salt auth_tokens. Defaults to `nil`.

  ### `session_ttl`

  How many seconds since the creation a session should last.
  Defaults to 7 days (`60 * 60 * 24 * 7`).

  ### `refresh_session_ttl`

  The number of seconds that should be added to the session expires at when
  calling `Session.changeset()`.
  `nil` to prevent this behaviour.
  Defaults to 7 days (`60 * 60 * 24 * 7`).

  """

  defmacro __using__(opts) do
    ecto_sessions_module = Keyword.get(opts, :ecto_sessions_module, EctoSessions)

    quote do
      @ecto_sessions_module unquote(ecto_sessions_module)

      @doc """
      Returns the length of the session auth token (from `auth_token_length` applicaton env).
      Defaults to `64`. Can be changed at any time, applies for new sessions only.
      """
      def get_auth_token_length(), do: get_env(:auth_token_length, 64)

      @doc """
      Returns the hashing algorithm to use (from `hashing_algorithm` aplicaton env).
      Can be one of the followng:
        - `:sha256` the default;
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
        - `nil` to not hash, and store tokens in plaintext;

      See [erlang's crypto `hash_algorithm()`](https://www.erlang.org/doc/man/crypto.html#type-hash_algorithm)
      for more information.
      """
      def get_hashing_algorithm(), do: get_env(:hashing_algorithm, :sha256)

      @doc """
      Optional *secret salt*, commonly known as *pepper* to be added to the
      auth token before hashing. Runtime configuration.
      **Once changed, invalidates all sessions, as lookup is no longer possible.**
      Can only be set if `hashing_algorithm` is not `nil`.
      Set to `nil` to not salt auth_tokens. Defaults to `nil`.
      """
      def get_secret_salt(), do: get_env(:secret_salt)

      @doc """
      How many seconds since the creation a session should last.
      Runtime configuration from `session_ttl`, defaults to 7 days (`60 * 60 * 24 * 7`).
      """
      def get_session_ttl(), do: get_env(:session_ttl, 60 * 60 * 24 * 7)

      @doc """
      The number of seconds that should be added to the session expires at when
      calling `Session.changeset()`.
      `nil` to prevent this behaviour.
      Runtime configuration from `refresh_session_ttl`, defaults to 7 days (`60 * 60 * 24 * 7`).
      """
      def get_refresh_session_ttl(), do: get_env(:refresh_session_ttl, 60 * 60 * 24 * 7)

      defp get_env(key, default \\ nil) do
        Application.get_env(
          :application.get_application(unquote(__CALLER__.module)),
          @ecto_sessions_module,
          []
        )
        |> Keyword.get(key, default)
      end
    end
  end

  @callback get_auth_token_length() :: non_neg_integer()
  @callback get_hashing_algorithm() :: atom()
  @callback get_secret_salt() :: binary() | nil
  @callback get_session_ttl() :: non_neg_integer()
  @callback get_refresh_session_ttl() :: non_neg_integer()
end
