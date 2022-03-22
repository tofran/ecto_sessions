defmodule EctoSessions do
  @moduledoc """
  This lib implements a set of methods to help you handle the storage and
  access to databse-backend sessions.

  It might be used, for example to authorize users via cookies or API keys.
  The medium you will use the sessions is up to the application implementation.

  Using database backed session, might be very helpful in some scenarios.
  It has quite a few benefits and drawbacks comparing to signed sessions,
  for example `JWT` or `Plug.Session`.

  Advantages:

    - Ability to query active sessions for a given user.
      Ex: view the devices where a user has a valid session;
    - Full control of the validity: at any time your application will be able to
      control if a given session is valid, change their expiration and even
      revalidate tokens at any time.
    - Ability to store arbitrary data, without increating the token size.

  Disadvantages:

    - Depending on the design, you might be adding a database query on each
      request - just like traditional sessions;
      Note that you can use a separate database for sessions, and furthermore
      this code can also be adapted for different backends, like key-value stores.
    - Clients and other services will not be able to inspect the contents of the token.

    A great design, that allows you to have the benefits of stateless and statefull
    sessions combined, is to use stateless sessions for short-lived tokens, and
    then database backend sessions for long-lived refresh tokens.
  """

  import Ecto.Query, warn: false

  alias EctoSessions.AuthToken
  alias EctoSessions.Config
  alias EctoSessions.Session

  @doc """
  Creates a session. `attrs` is a map that contains `EctoSessions.Session` attributes,
  where the keys are atoms.

  Uses `Ecto.Repo.insert/2`

  Example

    iex> create_session(%{user_id: "1234", data: %{device_name: "Samle Browser"}})
    %Session{
      user_id: "1234",
      data: %{
        device_name: "Samle Browser",
        plaintext_auth_token: "plaintext-auth-token"
        hashed_auth_token: "hashed-token"
      }
    }
  """
  def create_session(attrs) do
    %Session{}
    |> Session.changeset(attrs)
    |> Config.get_repo().insert()
  end

  @doc """
  Same as `create_session/1` but using `Ecto.Repo.insert!/2`
  """
  def create_session!(attrs) do
    %Session{}
    |> Session.changeset(attrs)
    |> Config.get_repo().insert!()
  end

  @doc """
  Creates a session using `create_session!/1` returing only the plaintext auth token.

  Example

    iex> create_session(%{user_id: "1234", data: %{device_name: "Samle Browser"}})
    "plaintext-auth-token"

  """
  def get_new_session_auth_token(attrs) do
    %{plaintext_auth_token: plaintext_auth_token} = create_session!(attrs)
    plaintext_auth_token
  end

  @doc """
  Returns an ecto query for sessions which have not expired:
  expires_at can either be null or in the future.
  """
  def get_valid_sessions_query() do
    from(
      session in Session,
      where:
        is_nil(session.expires_at) or
          session.expires_at > ^DateTime.utc_now()
    )
  end

  def get_session_query(:auth_token, plaintext_auth_token) do
    hashed_auth_token = AuthToken.hash(plaintext_auth_token)

    from(
      session in get_valid_sessions_query(),
      where: session.hashed_auth_token == ^hashed_auth_token
    )
  end

  def get_session_query(field_name, value) do
    from(
      session in get_valid_sessions_query(),
      where: field(session, ^field_name) == ^value
    )
  end

  @doc """
  Returns a session given the field name and the desired value to check for equality.
  If :auth_token is passed, hashing will be automatically handled.

  Uses `Ecto.Repo.one/1`
  """
  def get_session(field_name, value) do
    get_session_query(field_name, value)
    |> Config.get_repo().one()
  end

  @doc """
  Same as `get_session/2` but using `Ecto.Repo.one!/1`.
  """
  def get_session!(field_name, value) do
    get_session_query(field_name, value)
    |> Config.get_repo().one!()
  end

  @doc """
  Renovates a session expiration following the configuration in `EctoSession.Config`
  """
  def renovate_session(session) do
    Session.changeset(session)
    |> Config.get_repo().update!()
  end
end
