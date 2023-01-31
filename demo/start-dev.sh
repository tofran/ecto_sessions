#!/bin/sh

set -eu

echo "Migrating..."
mix ecto.migrate

echo "Finished migrations. Starting app..."
iex -S mix phx.server