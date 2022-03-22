defmodule EctoSessions.Config do
  @default_auth_token_length 64

  @moduledoc """
  Tis module handles ecto_sessions configuration.

  # Available configs

    - `repo`: Your ecto repository. Required runtime config.

    - `auth_token_length`: Runtime configuration for the length of the session auth token.
      It will be passed to `EctoSessions.AuthToken.generate`.
      Defaults to `#{@default_auth_token_length}`.
      Can be changed at any time, applies for new sessions only.

    - `table_name`: Compile-time configuration for the name of the table where to store Sessions.
      Defauts to `sessions`.

    - `hashing_algorithm`: The hashing algorithm to use:
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
        - `nil` to not hash, and store tokens in plain - not recommended;

      See [crypto's `hash_algorithm()`](https://www.erlang.org/doc/man/crypto.html#type-hash_algorithm)
      for more information

    - `hashing_secret_salt`: Optional global *secret* salt, commonly known as *Pepper*
      to be added to the auth token before hashing. Runtime configuration,
      that once changed, invalidates all sessions, as lookup is no longer possible.
      Only used if `hashing_algorithm` is not `nil`.
      Set to `nil` to not salt auth_tokens.
      Defaults to `nil`.

  # Example

  In your `config.exs`:

  ```
  config :ecto_sessions,
    repo: MyApp.Repo,
    auth_token_length: 128,
    sessions_table_name: "sessions",
    extra_fields: [:user_id],
    hashing_algorithm: :sha512,
    hashing_secret_salt: "my-unique-secret"
  ```

  """

  def get_auth_token_length() do
    get_env(:auth_token_length, @default_auth_token_length)
  end

  def get_sessions_table_name() do
    get_env(:sessions_table_name, "sessions")
  end

  def get_extra_fields() do
    get_env(:extra_fields, [:user_id])
  end

  def get_hashing_secret_salt() do
    get_env(:hashing_secret_salt)
  end

  def get_hashing_algorithm() do
    get_env(:hashing_algorithm, :sha256)
  end

  def get_repo() do
    get_env(:repo) || raise "Config repo not be defined."
  end

  defp get_env(key, default \\ nil) do
    Application.get_env(
      :ecto_sessions,
      key,
      default
    )
  end
end
