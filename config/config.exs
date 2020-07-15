use Mix.Config

config :trader, Cache,
  # 24 hrs
  gc_interval: 86_400

# import_config "#{Mix.env()}.exs"

config :trader, port: 4001
