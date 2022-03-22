defmodule EctoSessions.Config do
  @moduledoc """
  Tis module handles ecto_sessions configuration.
    - `sessions_table_name`: Runtime configuration for the length of the session auth token.
      It will be passed to `EctoSessions.AuthToken.generate`.
      Defaults to `64`.
      Can be changed at any time, applies for new sessions only.

    - `repo`: Your ecto repository. Required runtime config.

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

    - `extra_fields`: List of tuples with `{field_name, field_ecto_type}` for custom
      Session collumns. Both `field_name` and `field_ecto_type` must be an atom,
      and the later one must be an ecto type, for example `
      These fields are at the top level and not inside `data`.
      `data` is always a free JSON field that you can use to store anything your app needs.
      Although most databases allow indexes inside a json field, it may be more cumbersome
      to manage. extra_fields simplifies it by having collumns drectly in the session.
      Compile time configuration, defaults to `[{:user_id, :string}]`.
      To change this after the migration has been aplied:
        1. Ensure previous migrations have the previous `extra_fields` and are not relying
            in global configuration.
        2. Make the appropriate migration, addind removing or changing existing fields.

      Examples:
      ```
      extra_fields: []
      extra_fields: [{:user_id, :string}, {:ip_address, :string}]
      extra_fields: [{:user_id, :integer}, {:refresh_count, :integer}]
      extra_fields: [{:sample_date, :date}]
      ```

    - `session_ttl`: How many seconds since the creation a session should last.
      Runtime configuration, defaults to 7 days (`60 * 60 * 24 * 7`).

    - `refresh_session_ttl`: The number of seconds that the session should be renovated
      automatically when `Session.changeset()` is called.
      `nil` to prevent this behaviour.
      Runtime configuration, defaults to 7 days (`60 * 60 * 24 * 7`).

  # Example

  In your `config.exs`:

  ```
  config :ecto_sessions,
    repo: MyApp.Repo,
    auth_token_length: 128,
    sessions_table_name: "sessions",
    extra_fields: [{:user_id, :string}],
    hashing_algorithm: :sha512,
    hashing_secret_salt: "my-unique-secret",
    session_ttl: 60 * 60 * 24,
    refresh_session_ttl: 60 * 60 * 12
  ```

  """

  @doc false
  def get_auth_token_length(), do: get_env(:auth_token_length, 64)

  @doc false
  def get_sessions_table_name(), do: get_env(:sessions_table_name, "sessions")

  @doc false
  def get_extra_fields(), do: get_env(:extra_fields, [{:user_id, :string}])

  @doc false
  def get_extra_field_names() do
    get_extra_fields()
    |> Enum.map(fn {field_name, _field_type} -> field_name end)
  end

  @doc false
  def get_hashing_secret_salt(), do: get_env(:hashing_secret_salt)

  @doc false
  def get_hashing_algorithm(), do: get_env(:hashing_algorithm, :sha256)

  @doc false
  def get_repo(), do: get_env(:repo) || raise("Config repo not be defined.")

  @doc false
  def get_session_ttl(), do: get_env(:session_ttl, 60 * 60 * 24 * 7)

  @doc false
  def get_refresh_session_ttl(), do: get_env(:refresh_session_ttl, 60 * 60 * 24 * 7)

  defp get_env(key, default \\ nil) do
    Application.get_env(
      :ecto_sessions,
      key,
      default
    )
  end
end
