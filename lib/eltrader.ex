defmodule Trader do
  use Application

  def start(_type, _args) do
    children = [
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: Trader.Web.Endpoint,
        options: [port: Application.get_env(:webhook_processor, :port)]
      )
    ]

    opts = [strategy: :one_for_one, name: Trader.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
