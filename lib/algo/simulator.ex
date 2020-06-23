defmodule Simulator do
  @behaviour Configurable
  alias Trader.Cache

  @config %{
    hours: %R{
      range: 36..128,
      value: 36
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
    start_time = DateTime.utc_now() |> Timex.shift(hours: -(hours * 2))
    end_time = DateTime.utc_now()
    # step = Util.to_ms(interval)

    frames = Candles.candles(symbol, interval, start_time, end_time)

    [frame | frames] = frames
    sim([frame], frames, 0)
  end

  def sim(frames) do
    Algo.run(frames)
  end

  def sim(_, [], _), do: []

  def sim(frames, [frame | tail], index) do
    IO.puts("Simulating frame #{index}...")
    [sim(frames), sim(frames ++ [frame], tail, index + 1)]
  end
end
