defmodule TrendLines do
  @derive Jason.Encoder
  defstruct top_lines: [], bottom_lines: [], top_anchors: [], bottom_anchors: []

  defp create_lines(_, [], _), do: []
  defp create_lines(_, [_], _), do: []

  defp create_lines(frames, [a, b | tail], type) do
    {p1, p2} =
      case type do
        :top -> {{a.x, a.y}, {b.x, b.y}}
        :bottom -> {{a.x, a.y}, {b.x, b.y}}
      end

    p1 = %Geo.Point{coordinates: p1}
    p2 = %Geo.Point{coordinates: p2}

    [
      case type do
        :top -> Line.new(frames, p1, p2, [a.frame, b.frame])
        :bottom -> Line.new(frames, p1, p2, [a.frame, b.frame])
      end
      | create_lines(frames, [b | tail], type)
    ]
  end

  # def merge_length(frames, lines) do
  # end

  def new(%{frames: frames, strong_points: {_, top, bottom}}) do
    %TrendLines{
      top_lines: create_lines(frames, top, :top),
      bottom_lines: create_lines(frames, bottom, :bottom)
    }
  end
end
