defmodule Frame do
  defstruct candle: nil,
            frames: [],
            index: -1,
            momentum: 0

  def new(candle, frames) do
    %Frame{candle: candle, frames: frames}
  end

  def calculate_momentum(frames, index, config) do
    open = Enum.at(frames, index - config.momentum_width).open
    close = Enum.at(frames, index)

    close - open
  end
end
