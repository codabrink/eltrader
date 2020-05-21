defmodule Algo do
  def run() do
    config = %Algo.Config{}

    ApiData.candles()
    |> to_frames(0, nil, config)
    |> (&Reversal.merge_reversals(&1, &1, config)).()
  end

  defp to_frames([], _i, _prev, _config), do: []

  defp to_frames([candle | tail], i, prev, config) do
    frame =
      Frame.new(
        %Frame{
          candle: candle,
          index: i,
          prev: prev
        },
        config
      )

    [frame | to_frames(tail, i + 1, frame, config)]
  end
end
