defmodule TrendLines do
  defstruct top_lines: [], bottom_lines: []

  defp create_lines(_, [], _), do: []
  defp create_lines(_, [_], _), do: []

  defp create_lines(frames, [a, b | tail], type) do
    {p1, p2} =
      case type do
        :top -> {{a.index, a.high}, {b.index, b.high}}
        :bottom -> {{a.index, a.low}, {b.index, b.low}}
      end

    p1 = %Geo.Point{coordinates: p1}
    p2 = %Geo.Point{coordinates: p2}

    [
      case type do
        :top -> Line.new(frames, a, p1, p2, [a, b])
        :bottom -> Line.new(frames, a, p1, p2, [a, b])
      end
      | create_lines(frames, [b | tail], type)
    ]
  end

  # def merge_length(frames, lines) do
  # end

  @spec new([%Frame{}]) :: %TrendLines{}
  def new(frames) do
    anchor_count = floor(C.fetch(:reversal_anchor_pct) / 100 * length(frames))

    bottom_anchors =
      frames
      |> Enum.sort(fn f1, f2 -> f1.bottom_dominion >= f2.bottom_dominion end)
      |> Enum.slice(0..anchor_count)
      |> Enum.sort(fn f1, f2 -> f1.close_time <= f2.close_time end)

    top_anchors =
      frames
      |> Enum.sort(fn f1, f2 -> f1.top_dominion >= f2.top_dominion end)
      |> Enum.slice(0..anchor_count)
      |> Enum.sort(fn f1, f2 -> f1.close_time <= f2.close_time end)

    %TrendLines{
      # top_anchors: top_anchors,
      # bottom_anchors: bottom_anchors,
      top_lines: create_lines(frames, top_anchors, :top),
      bottom_lines: create_lines(frames, bottom_anchors, :bottom)
    }
  end
end
