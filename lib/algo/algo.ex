defmodule Algo do
  def run() do
    ApiData.candles()
    |> to_frames(0, nil, %Algo.Config{})
  end

  defp to_frames([], _i, _prev, _config), do: []

  defp to_frames([head | tail], i, prev, config) do
    frame =
      Frame.new(
        %Frame{
          candle: head,
          index: i,
          prev: prev
        },
        config
      )

    [frame | to_frames(tail, i + i, frame, config)]
  end
end
