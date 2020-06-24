defmodule TrendLines do
  @derive Jason.Encoder
  defstruct top_lines: [], bottom_lines: [], top_anchors: [], bottom_anchors: []

  defp create_lines(_, []), do: []
  defp create_lines(_, [_]), do: []

  defp create_lines(frame, [a, b | tail]),
    do: [Line.new(frame, a, b) | create_lines(frame, [b | tail])]

  # def merge_length(frames, lines) do
  # end

  def new(frame) do
    {_, bottom, top} = frame.strong_points

    %TrendLines{
      top_lines: create_lines(frame, top),
      bottom_lines: create_lines(frame, bottom)
    }
  end
end
