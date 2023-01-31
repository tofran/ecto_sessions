# Ecto Sessions

**Database backend sessions with Ecto.**

[![ecto_sessions in hex.pm](https://img.shields.io/hexpm/v/ecto_sessions?style=flat)](https://hex.pm/packages/ecto_sessions)
[![ecto_sessions documentation](https://img.shields.io/badge/hex.pm-docs-green.svg?style=flat)](https://hexdocs.pm/ecto_sessions/)


`ecto_sessions` helps you easily and securely manage database backed sessions
in your Ecto project.

It might be used, for example to manage authorization via cookies or API keys.
The medium you will use the sessions is up to the application implementation.
Ex: session id to be used in a Cookie or `X-Api-Token` for a REST API.

Using database backed session, might be very helpful in some scenarios.
It has quite a few benefits and drawbacks comparing to signed sessions,
for example `JWT` or signed cookies. It might also be used in combination
with them.

Advantages:

  - Ability to query active sessions for a given user.
    Ex: list the devices where a user has a valid session or lit the active
    API keys for a given project.
  - Full control of the validity: at any time your application will be able to
    control if a given session is valid, change their expiration and even
    revalidate expired tokens.
  - Ability to store arbitrary data, without increasing the token size.
    Ex: Device/token name, permissions, metadata, etc.

Disadvantages:

  - Depending on the design, you might be adding a database query on each
    request - just like traditional sessions;
    Note that you can use a separate database, and furthermore this code
    might also be adapted for different backends, like key-value stores.
  - Clients and other services will not be able to inspect the contents 
    of the token. This might be useful for example to predict if a token
    is expired before making a request.
    This might also be considered an advantage in scenarios you don't want
    to give any control to the client.

One design that allows you to have the benefits of stateless and
stateful sessions combined, is to have *short-lived signed tokens*,
and database backed sessions for *long-lived refresh tokens*.


## Installation

The package can be installed by adding `ecto_sessions`
to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ecto_sessions, "~> 0.1.0"}
  ]
end
```

Then, in your ecto app create the following module:

```elixir
defmodule MyApp.Sessions do
  use EctoSessions,
    repo: MyApp.Repo
end
```

Refer to [EctoSessions module documentation](https://hexdocs.pm/ecto_sessions/EctoSessions.html) for more details.

