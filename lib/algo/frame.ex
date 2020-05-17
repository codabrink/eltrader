defmodule Frame do
  defstruct candle: nil,
            frames: [],
            index: -1,
            momentum: 0

  def new(candle: candle, frames: frames, index: index, config: config) do
    momentum = Frame.calculate_momentum(candle, frames, index, config)
    %Frame{candle: candle, frames: frames, index: index, momentum: momentum}
  end

  def calculate_momentum(candle, frames, index, config) do
    open = Enum.at(frames, index - config.momentum_width).open
    candle.close - open
  end
end
