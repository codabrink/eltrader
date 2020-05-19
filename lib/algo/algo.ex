defmodule Algo do
  def run() do
    Algo.generate_frames(ApiData.candles(), %Trader.Config{})
  end

  def generate_frames(candles, config) do
    candles
    |> Enum.with_index()
    |> Enum.reduce(%{prev: nil, frames: []}, fn {c, i}, acc ->
      frame = %Frame{
        candle: c,
        index: i,
        prev: acc.prev
      }

      %{prev: frame, frames: [acc.frames | frame]}
    end)
  end
end
