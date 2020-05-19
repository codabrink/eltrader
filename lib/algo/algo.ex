defmodule Algo do
  def run() do
    Algo.generate_frames(ApiData.candles(), %Trader.Config{})
  end

  def generate_frames(candles, config) do
    %{frames: frames} =
      candles
      |> Enum.with_index()
      |> Enum.reduce(%{prev: nil, frames: []}, fn {c, i}, acc ->
        frame =
          Frame.new(
            %Frame{
              candle: c,
              index: i,
              prev: acc.prev
            },
            config
          )

        %{prev: frame, frames: acc.frames ++ [frame]}
      end)

    frames
  end
end
