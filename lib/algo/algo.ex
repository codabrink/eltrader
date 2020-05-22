defmodule Algo do
  def run() do
    C.init()

    ApiData.candles()
    |> to_frames(0, nil)
    |> Reversal.reversals()
  end

  defp to_frames([], _, _), do: []

  defp to_frames([candle | tail], i, prev) do
    frame =
      Frame.new(%Frame{
        candle: candle,
        index: i,
        prev: prev
      })

    [frame | to_frames(tail, i + 1, frame)]
  end
end
