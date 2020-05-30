defmodule Frame.Lines do
  defstruct top_anchors: [], bottom_anchors: [], top_lines: [], bottom_lines: []

  @spec new([%Frame{}]) :: %Frame.Lines{}
  def new(frames) do
    anchor_count = floor(C.fetch(:reversal_anchor_pct) / 100 * length(frames))

    bottom_anchors =
      frames
      |> Enum.sort(fn f1, f2 -> f1.bottom_distance >= f2.bottom_distance end)
      |> Enum.slice(0..anchor_count)

    top_anchors =
      frames
      |> Enum.sort(fn f1, f2 -> f1.top_distance >= f2.top_distance end)
      |> Enum.slice(0..anchor_count)

    %Frame.Lines{
      top_anchors: top_anchors,
      bottom_anchors: bottom_anchors,
      top_lines: lines(top_anchors, :top),
      bottom_lines: lines(bottom_anchors, :bottom)
    }
  end

  defp lines([], _type), do: []

  defp lines([frame | tail], type) do
    [Line.new(frame, type) | lines(tail, type)]
  end
end
