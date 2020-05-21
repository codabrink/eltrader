defmodule Reversal do
  defstruct [:type, :strength]

  def merge_reversals([], _, _), do: []

  def merge_reversals([frame | tail], frames, config) do
    surrounding = Frame.surrounding(frames, frame.index, config.reversal_min_distance)

    reversals = [
      bottom_reversal(surrounding, frame, config),
      top_reversal(surrounding, frame, config)
    ]

    [
      %Frame{
        frame
        | reversals: Enum.filter(reversals, & &1)
      }
      | merge_reversals(tail, frames, config)
    ]
  end

  def bottom_reversal([], _, _), do: %Reversal{type: :bottom}

  def bottom_reversal([head | tail], frame, config) do
    cond do
      head.candle.low < frame.candle.low -> nil
      true -> bottom_reversal(tail, frame, config)
    end
  end

  def top_reversal([], _, _), do: %Reversal{type: :top}

  def top_reversal([head | tail], frame, config) do
    cond do
      head.candle.high > frame.candle.high -> nil
      true -> top_reversal(tail, frame, config)
    end
  end
end
