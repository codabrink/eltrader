defmodule Algo do
  import Util

  @default_symbol "BTCUSDT"
  @default_interval "5m"
  use Configurable,
    config: %{
      frame_list_max: %R{
        value: 200
      }
    }

  defmodule Payload do
    @derive Jason.Encoder
    use TypedStruct

    typedstruct do
      field :frames, [%Frame{}]
    end
  end

  def run(), do: run(@default_symbol, @default_interval)

  def run(frames), do: frames |> annotate()
  def run(symbol, interval), do: Candles.candles(symbol, interval) |> run()

  def annotate(), do: annotate(@default_symbol, @default_interval)
  def annotate(symbol, interval), do: Candles.candles(symbol, interval) |> annotate()

  def annotate(frames) do
    C.init()

    frames =
      to_frames(frames, 0, nil)
      |> double_link()
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
    TestUtil.enable()
    run()
    TestUtil.disable()
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
