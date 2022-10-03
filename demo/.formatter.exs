[
  import_deps: [
    :ecto,
    :phoenix,
    :plug_cowboy
  ],
  inputs: ["*.{ex,exs}", "priv/*/seeds.exs", "{config,lib,test}/**/*.{ex,exs}"],
  subdirectories: ["priv/*/migrations"]
]
