defmodule Algo do
  @default_symbol "BTCUSDT"
  @default_interval "15m"

  defmodule Payload do
    @derive Jason.Encoder
    use TypedStruct

    typedstruct do
      field :frames, [%Frame{}]
    end
  end

  def run(), do: run(@default_symbol, @default_interval)

  def run(candles), do: candles |> annotate()
  def run(symbol, interval), do: Candles.candles(symbol, interval) |> run()

  def annotate(), do: annotate(@default_symbol, @default_interval)
  def annotate(symbol, interval), do: Candles.candles(symbol, interval) |> annotate()

  def annotate(candles) do
    C.init()

    frames =
      to_frames(candles, 0, nil)
      |> Frame.merge_dominion()
      |> Reversal.merge_reversals()
      |> Frame.zip_frames()
      |> Frame.complete()

    %Payload{
      frames: frames
    }
  end

  def votes_for(symbol, interval, frame) do
    sim_width_hours = C.fetch(:sim_width_hours)

    end_time =
      frame.open_time
      |> DateTime.from_unix!(:millisecond)

    start_time = end_time |> Timex.shift(hours: -sim_width_hours)

    Candles.candles(symbol, interval, start_time, end_time)
  end

  def quiet() do
    annotate()
    nil
  end

  defp to_frames([], _, _), do: []

  defp to_frames([frame | tail], i, prev) do
    frame =
      Frame.new(
        frame,
        prev,
        i,
        nil
      )

    [
      frame
      | to_frames(tail, i + 1, frame)
    ]
  end
end
