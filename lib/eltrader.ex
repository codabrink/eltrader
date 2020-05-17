defmodule Trader do
  def run() do
    children = [
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: Trader.Web.Endpoint,
        options: [port: Application.get_env(:trader, :port)]
      )
    ]

    opts = [strategy: :one_for_one, name: Trader.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
