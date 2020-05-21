defmodule Frame do
  @derive {Poison.Encoder, except: [:prev]}
  defstruct [:candle, :index, :momentum, :prev, reversals: []]

  def new(frame) do
    %Frame{
      frame
      | momentum: calculate_momentum(frame)
    }
  end

  def calculate_momentum(frame) do
    find_frame(frame, frame.index - C.fetch(:momentum_width))
    |> case do
      nil -> 0
      f -> frame.candle.close - f.candle.open
    end
  end

  def find_frame(nil, _), do: nil

  def find_frame(frame, index) do
    case frame.index do
      ^index -> frame
      _ -> find_frame(frame.prev, index)
    end
  end

  def surrounding(frames, index, n) do
    Enum.slice(frames, Enum.max([index - n, 0]), n * 2 + 1)
  end
end
