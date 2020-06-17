defmodule Trader.Cache do
  use Nebulex.Cache,
    otp_app: :trader,
    adapter: Nebulex.Adapters.Local
end
