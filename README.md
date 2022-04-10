# Ecto Sessions: database backend sessions with Ecto


`ecto_sessions` helps you easily and securely manage database backed sessions
in your Ecto project.

It might be used, for example to manage authorization via cookies or API keys.
The medium you will use the sessions is up to the application implementation.
Ex: session id to be used in a Cookie or X-Api-Token for a REST API.

Using database backed session, might be very helpful in some scenarios.
It has quite a few benefits and drawbacks comparing to signed sessions,
for example `JWT` or signed cookies. It might also be used in combination
with the later.

Advantages:

  - Ability to query active sessions for a given user.
    Ex: list the devices where a user has a valid session;
  - Full control of the validity: at any time your application will be able to
    control if a given session is valid, change their expiration and even
    revalidate expired tokens at any time.
  - Ability to store arbitrary data, without increasing the token size.

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
and then database backend sessions for long-lived *refresh tokens*.


## Installation

[Available on Hex](https://hex.pm/packages/ecto_sessions)

The package can be installed by adding `ecto_sessions`
to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ecto_sessions, "~> 0.1.0"}
  ]
end
```

The documentation can be found at
[https://hexdocs.pm/ecto_sessions](https://hexdocs.pm/ecto_sessions).
