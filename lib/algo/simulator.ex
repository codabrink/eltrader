defmodule Simulator do
  use Configurable,
    config: %{
      hours: %R{
        range: 36..128,
        value: 36
      }
    }

  def run(symbol \\ "BTCUSDT", interval \\ "15m")
      when is_bitstring(symbol) and is_bitstring(interval) do
    hours = config(:hours)
    start_time = DateTime.utc_now() |> Timex.shift(hours: -(hours * 2))
    end_time = DateTime.utc_now()
    # step = Util.to_ms(interval)

    frames = Candles.candles(symbol, interval, start_time, end_time)

    [frame | frames] = frames
    simulation = annotate([frame], frames, 0)
    simulation = Enum.take(simulation, -floor(length(simulation) / 2))

    IO.puts("Running purchases...")
    stake = Api.Sim.new(9_000)
    frames = sim(simulation, stake)

    last_frame = List.last(frames)
    stake = last_frame.stake
    IO.inspect(Api.Sim.value(stake, last_frame))
  end

  def annotate(frames) do
    Algo.run(frames)
  end

  def annotate(_, [], _), do: []

  def annotate(frames, [frame | tail], index) do
    IO.puts("Simulating frame #{index}...")
    [annotate(frames) | annotate(frames ++ [frame], tail, index + 1)]
  end

  def sim([], _), do: []

  def sim([payload | tail], stake) do
    frame = sim(List.last(payload.frames), stake)
    [frame | sim(tail, frame.stake)]
  end

  def sim(frame, stake) do
    Decider.decide(frame, stake)
  end
end
