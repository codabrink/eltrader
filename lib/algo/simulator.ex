defmodule Simulator do
  @behaviour Configurable
  alias Trader.Cache

  @config %{
    hours: %R{
      range: 36..128,
      value: 36,
      step: 1
    }
  }

  @impl Configurable
  def config(), do: __MODULE__ |> to_string |> Cache.config() || @config

  def config(key) do
    %{^key => %{:value => value}} = config()
    value
  end

  def run(symbol \\ "BTCUSDT", interval \\ "15m")
      when is_bitstring(symbol) and is_bitstring(interval) do
    hours = config(:hours)
    start_time = DateTime.utc_now() |> Timex.shift(days: -(hours * 2))
    end_time = DateTime.utc_now()
    step = Util.to_ms(interval)

    candles = Candles.candles(symbol, interval, start_time, end_time)
    half_index = floor(length(candles) / 2)

    head = Enum.take(candles, half_index)
    tail = Enum.slice(candles, half_index, length(candles) - half_index)
    sim(head, tail, 1, half_index)
  end

  def sim([], _, _, _), do: []
  def sim(_, [], _, _), do: []

  def sim([_ | head], [candle | tail], index, length) do
    IO.puts("Simulating #{index} of #{length}...")
    [Algo.run(head) | sim(head ++ [candle], tail, index + 1, length)]
  end
end
