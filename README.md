# Ecto sessions: database backend sessions with ecto

 This lib implements a set of methods to help you handle the storage and
  access to sessions.

  It might be used, for example to authorize users via cookies or API keys.
  The medium you will use the sessions is up to the application implementation.

  Using database backed session, might be very helpful in some scenarios.
  It has quite a few benefits and drawbacks comparing to signed sessions,
  for example `JWT` or `Plug.Session`.

  Advantages:

    - Ability to query active sessions for a given user.
      Ex: view the deviced where a user has a valid session;
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

## Installation

**TODO: Publish to hex**

[Available in Hex](https://hex.pm/docs/publish)

The package can be installed
by adding `ecto_sessions` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ecto_sessions, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/ecto_sessions](https://hexdocs.pm/ecto_sessions).
