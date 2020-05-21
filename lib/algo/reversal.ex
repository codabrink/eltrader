defmodule Reversal do
  defstruct [:type, :strength, :prev, :prev_of_type, :diff, :frame]

  def merge_reversals(frames), do: merge_reversals(frames, frames)

  def merge_reversals([], _), do: []

  def merge_reversals([frame | tail], frames) do
    [
      %Frame{
        frame
        | reversals: reversals(frames, frame)
      }
      | merge_reversals(tail, frames)
    ]
  end

  def reversals(frames, frame) do
    surrounding = Frame.surrounding(frames, frame.index, C.fetch(:reversal_min_distance))

    Enum.filter(
      [
        create_reversal(:top, surrounding, frame),
        create_reversal(:bottom, surrounding, frame)
      ],
      & &1
    )
  end

  defp create_reversal(type, [], frame), do: %Reversal{type: type, frame: frame}

  defp create_reversal(type, [head | tail], frame) do
    cond do
      type == :top && head.candle.high > frame.candle.high -> nil
      type == :bottom && head.candle.low < frame.candle.low -> nil
      true -> create_reversal(type, tail, frame)
    end
  end
end
