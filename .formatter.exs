[
  import_deps: [
    :ash_oban,
    :oban,
    :ash_ai,
    :ash_authentication_phoenix,
    :ash_authentication,
    :ash_phoenix,
    :ash_postgres,
    :ecto,
    :ecto_sql,
    :phoenix
  ],
  subdirectories: ["priv/*/migrations"],
  plugins: [Spark.Formatter, Phoenix.LiveView.HTMLFormatter],
  inputs: ["*.{heex,ex,exs}", "{config,lib,test}/**/*.{heex,ex,exs}", "priv/*/seeds.exs"]
]
