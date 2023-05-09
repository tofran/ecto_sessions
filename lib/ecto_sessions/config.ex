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
    extend_session_stale_time: 60 * 60 * 6,
    auto_extend_session: true
  ```

  ## Configuration options

  ### `auth_token_length`

  The length of the session auth token (from `auth_token_length` application env).
  Defaults to `64`. Can be changed at any time, applies for new sessions only.

  ### `hashing_algorithm`

  The hashing algorithm to use (from `hashing_algorithm` application env).
  Can be one of the following:

  - `:sha`
  - `:sha224`
  - `:sha256` (the default)
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

  ### `secret_salt`

  The Optional *secret salt*, commonly known as *pepper* to be added to the
  auth token before hashing.
  Runtime configuration.

  **Once changed, invalidates all sessions, as lookup is no longer possible.**
  Can only be set if `hashing_algorithm` is not `nil`.
  Set to `nil` to not salt auth_tokens. Defaults to `nil`.

  ### `session_ttl`

  For how many should the session be valid. Both since its creation or when extended.
  Runtime configuration from `session_ttl`, defaults to 7 days (`60 * 60 * 24 * 7`).

  ### `extend_session_stale_time`

  The number of seconds from the `session_ttl` to consider the session as needing to
  be extended, it is a threshold, to keep the value unchanged.
  This prevents constant update of the session `expires_at`.
  When this threshold has been met, the Session's `expires_at` will be updated to _now_ plus the
  `session_ttl`.
  Set to `nil` to prevent session extending, and `0` to extend it every time.

  Session extending is attempted (if enabled), when:
  - Calling `EctoSessions.get_session` or `EctoSessions.get_session!` when the config
    `auto_extend_session` is `true`.
  - Calling `EctoSessions.get_session` or `EctoSessions.get_session!` and passing
    the option `:should_extend_session` as `true` (overrides the default).
  - Manually calling `EctoSessions.extend_session`.
  - Manual update passing tru `Session.changeset` is called.

  Runtime configuration. Defaults to 1 day (`60 * 60 * 24`).
  Must be lower than `session_ttl`.

  ### `auto_extend_session`

  The default value for the `:should_extend_session` option, used when not explicitly passed to
  `EctoSessions.get_session` and `EctoSessions.get_session!`.
  When `true`, session extending is attempted automatically after retrieving a single session.
  Set to `false` to prevent this behaviour.

  Runtime configuration, defaults to `true`.
  Should only be set if `extend_session_stale_time` is not `nil`.
  See `extend_session_stale_time` above for more information.

  """

  defmacro __using__(opts) do
    ecto_sessions_module = Keyword.get(opts, :ecto_sessions_module, EctoSessions)

    quote do
      @ecto_sessions_module unquote(ecto_sessions_module)

      def get_auth_token_length(), do: get_env(:auth_token_length, 64)

      def get_hashing_algorithm(), do: get_env(:hashing_algorithm, :sha256)

      def get_secret_salt(), do: get_env(:secret_salt)

      def get_session_ttl(), do: get_env(:session_ttl, 60 * 60 * 24 * 7)

      def get_extend_session_stale_time(), do: get_env(:extend_session_stale_time, 60 * 60 * 24)

      def get_auto_extend_session(), do: get_env(:auto_extend_session, true)

      defp get_env(key, default \\ nil) do
        {:ok, application} = :application.get_application(unquote(__CALLER__.module))

        Application.get_env(
          application,
          @ecto_sessions_module,
          []
        )
        |> Keyword.get(key, default)
      end
    end
  end

  @doc """
  Returns the config `auth_token_length`.
  """
  @callback get_auth_token_length() :: non_neg_integer()

  @doc """
  Returns the config `hashing_algorithm`.
  """
  @callback get_hashing_algorithm() :: atom()

  @doc """
  Returns the config `secret_salt`.
  """
  @callback get_secret_salt() :: binary() | nil

  @doc """
  Returns the config `session_ttl`.
  """
  @callback get_session_ttl() :: non_neg_integer()

  @doc """
  Returns the config `extend_session_stale_time`.
  """
  @callback get_extend_session_stale_time() :: non_neg_integer()

  @doc """
  Returns the config `auto_extend_session`.
  """
  @callback get_auto_extend_session() :: boolean()
end
