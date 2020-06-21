defmodule Simulator do
  alias Trader.Cache

  @behaviour Configurable
  @config %{
    sim_width: %R{
      range: 36..128,
      value: 36
    }
  }

  @impl Configurable
  def config(), do: @config

  def config(key, config \\ @config) do
    %{^key => %{:value => value}} = config
    value
  end

  def run(interval \\ "15m") when is_bitstring(interval) do
    cache = Cache.config("Simulator")

    start_time = DateTime.utc_now() |> Timex.shift(days: -3)
    end_time = DateTime.utc_now()
    step = Util.to_ms(interval)
  end
end
