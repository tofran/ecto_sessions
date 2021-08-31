defmodule EctoSessions do
  @moduledoc """
  This lib implements a set of methods to help you handle the storage and access to sessions.

  **Session** is an entity with:
    - `id`: a unique identifier of the session. Ex: session id to be used in a cookie.
    - `data`: any data that corresponds to this session. Ex: user_id and ui theme.

  It might be used, for example to authorize users via cookies or API keys. The medium you will use the sessions is up to the implementation.

  Using database backed session, might be very helpful in some scenarios. It has a few benefits and drawbacks comparing to signed sessions, for example JWT or `Plug.Session`.

  Advantages:

    - Query active sessions by data (for example user id);
    - Full control of the validity: you are able to control the expiration of your sessions, change their expiration and even revalidate tokens at any time.
    - Ability to store arbitrary data, without increating the token size.

  Disadvantages:

    - Authorization load will be in the database. Depending on the design, you might be adding a database query on each request (just like traditional sessions);
    - Clients and other services will not be able to inspect the contents of the token.

  """
end
