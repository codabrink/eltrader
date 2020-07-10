defmodule TrendLine do
  @derive Jason.Encoder
  use Configurable,
    config: %{
      min_slope_delta: %R{
        value: fn y -> y * 10000 end
      }
    }

  defstruct lines: []

  def generate(%Frame{} = frame) do
    strong_points = frame.strong_points

    %{
      bottom: generate(Enum.filter(strong_points, &(&1.type === :bottom)), frame),
      top: generate(Enum.filter(strong_points, &(&1.type === :top)), frame)
    }
  end

  def generate([], _), do: []

  def generate([sp | strong_points], frame),
    do: [create(sp, frame) | generate(strong_points, frame)]

  def create(%Point{points_after_of_type: points} = sp, mframe) do
    lines =
      _create([], sp, Enum.take(points, 15), mframe)
      |> group_by_slope_delta()
      |> merge_similar_slope_lines()

    %TrendLine{
      lines: lines
    }
  end

  defp _create(lines, _, [], _), do: lines

  defp _create([], sp, [p | points], mframe),
    do: _create([Line.new(mframe, sp, p)], sp, points, mframe)

  defp _create(lines, sp, [p | points], mframe) do
    [Line.new(mframe, sp, p) | lines]
    # |> slope_increased_enough?(sp)
    |> Enum.sort_by(& &1.slope)
    # |> crossed_on_next_frame?(sp, p, mframe)
    |> is_line_worthless_still?(p)
    |> _create(sp, points, mframe)
  end

  # Don't keep the line if it goes nowhere
  def is_line_worthless_still?([line | lines], %{x: px}) do
    case elem(line.p2, 0) do
      ^px -> lines
      _ -> [line | lines]
    end
  end

  def group_by_slope_delta([line | lines]), do: group_by_slope_delta(lines, [[line]])

  def group_by_slope_delta([line1 | lines], [[line2 | rest] | groups]) do
    delta = abs(line1.slope - line2.slope)

    cond do
      delta < elem(line1.p1, 1) * 0.0001 ->
        group_by_slope_delta(lines, [[line1, line2 | rest] | groups])

      true ->
        group_by_slope_delta(lines, [[line1], [line2 | rest] | groups])
    end
  end

  def group_by_slope_delta([], groups), do: groups

  def merge_similar_slope_lines([], %Line{} = preferred_line), do: preferred_line

  def merge_similar_slope_lines([%Line{} = line | lines], preferred_line) do
    {r1n, r1d} = line.respect
    {r2n, r2d} = preferred_line.respect

    cond do
      r1n > r2n or
          (r1n === r2n and r1d < r2d) ->
        merge_similar_slope_lines(lines, line)

      true ->
        merge_similar_slope_lines(lines, preferred_line)
    end
  end

  def merge_similar_slope_lines([]), do: []

  def merge_similar_slope_lines([[line | lines] | groups]) do
    [merge_similar_slope_lines(lines, line) | merge_similar_slope_lines(groups)]
  end

  def slope_increased_enough?([line, prev | lines], %{type: type} = sp) do
    delta = abs(line.slope - prev.slope)
    min_slope_delta = config(:min_slope_delta).(elem(line.p1, 1))

    cond do
      # If the angle has not changed enough
      delta < min_slope_delta ->
        cond do
          Util.between?(Line.y_at(prev, sp.frame.index), sp.frame.open, sp.frame.next.close) ->
            [line | lines]

          true ->
            [prev | lines]
        end

      # (type === :top && line.slope > prev.slope) ||
      # (type === :bottom && line.slope < prev.slope) ->
      # [line, prev | lines]

      true ->
        [line, prev | lines]
    end
  end

  defp crossed_on_next_frame?([line | lines], root, p, mframe) do
    cond do
      closed_on?(line, root.frame.next) ->
        root = Point.move_right(root)
        crossed_on_next_frame?([Line.new(mframe, root, p) | lines], root, p, mframe)

      closed_on?(line, p.frame.next) ->
        p = Point.move_right(p)
        crossed_on_next_frame?([Line.new(mframe, root, p) | lines], root, p, mframe)

      true ->
        [line | lines]
    end
  end

  defp closed_on?(_, nil), do: false

  defp closed_on?(line, frame) do
    Util.between?(Line.y_at(line, frame.index), frame.open, frame.close)
  end
end
