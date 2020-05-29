defmodule Frame do
  @derive {Poison.Encoder, except: [:prev]}
  defstruct [
    :open_time,
    :open,
    :high,
    :low,
    :close,
    :volume,
    :asset_volume,
    :close_time,
    :num_trades,
    :body_geom,
    :stem_geom,
    :index,
    :momentum,
    :prev,
    :top_reversal,
    :bottom_reversal,
    :wick,
    :lines
  ]

  def new(candle, prev, index) do
    frame = struct(Frame, Map.from_struct(candle))

    %Frame{
      frame
      | prev: prev,
        index: index,
        momentum: calculate_momentum(candle, prev, index)
    }
  end

  def calculate_momentum(candle, prev, index) do
    find_frame(prev, index - C.fetch(:momentum_width))
    |> case do
      nil -> 0
      f -> candle.close - f.open
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
