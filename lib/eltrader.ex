defmodule Trader do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: Api.Endpoint,
        options: [port: Application.get_env(:trader, :port)]
      ),
      Cache
    ]

    opts = [strategy: :one_for_one, name: Trader.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
