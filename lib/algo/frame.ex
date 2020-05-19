defmodule Frame do
  @derive {Poison.Encoder, except: [:prev]}
  defstruct [:candle, :index, :momentum, :prev]

  def new(frame, config) do
    momentum = Frame.calculate_momentum(frame, config)
    %Frame{frame | momentum: momentum}
  end

  def calculate_momentum(frame, config) do
    open = Frame.find_frame(frame, -config.momentum_width).open
    frame.candle.close - open
  end

  def find_frame(nil, _), do: nil

  def find_frame(frame, index) do
    index = if index < 0, do: frame.index + index

    cond do
      frame.index == index -> frame
      true -> find_frame(frame.prev, index)
    end
  end
end
