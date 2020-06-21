defmodule Trader.Cache do
  use Nebulex.Cache,
    otp_app: :trader,
    adapter: Nebulex.Adapters.Local

  def config(name) when is_binary(name), do: get("config_" <> name)
end
