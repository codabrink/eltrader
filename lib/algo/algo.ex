defmodule Algo do
  def run() do
    Algo.generate_frames(ApiData.candles(), %Algo.Config{})
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

  def generate_frames(candles, config) do
    to_frames(candles, 0, nil, config)
  end
end
