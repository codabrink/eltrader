defmodule Algo do
  defmodule Payload do
    defstruct [:frames, :trend_lines]
  end

  def run() do
    C.init()

    candles = ApiData.candles()

    frames =
      to_frames(candles, 0, nil)
      |> Frame.merge_dominion()
      |> Reversal.merge_reversals()

    %Payload{
      frames: frames,
      trend_lines: TrendLines.new(frames)
    }
  end

  defp to_frames([], _, _), do: []

  defp to_frames([candle | tail], i, prev) do
    frame =
      Frame.new(
        candle,
        prev,
        i
      )

    [frame | to_frames(tail, i + 1, frame)]
  end
end
