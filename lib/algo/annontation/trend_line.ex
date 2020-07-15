defmodule TrendLine do
  @derive Jason.Encoder
  use Configurable,
    config: %{
      min_angle_delta: %R{
        value: :math.pi() / 128
      }
    }

  defstruct lines: []

  def generate(%{points: %{strong: %{bottom: bottom, top: top}}} = frame) do
    # late_points = Enum.take(frame.points.all, -floor(length(frame.points.all) * 0.2))

    late_strong_points_bottom = Enum.take(bottom, -4)
    late_strong_points_top = Enum.take(top, -4)

    %{
      bottom: generate(late_strong_points_bottom, frame),
      top: generate(late_strong_points_top, frame),
      strong_top: generate_strong(top, frame),
      strong_bottom: generate_strong(bottom, frame)
    }
  end

  def generate([%{points_after_of_type: points} = root | roots], frame),
    do: [create(root, points, frame) | generate(roots, frame)]

  def generate([], _), do: []

  def generate_strong([%{strong_points_after_of_type: points} = root | roots], frame),
    do: [create(root, points, frame) | generate_strong(roots, frame)]

  def generate_strong([], _), do: []

  def create(root, points, mframe) do
    TestUtil.is_sorted(points, & &1.x)

    lines =
      _create([], root, Enum.take(points, 10), mframe)
      |> Enum.sort_by(& &1.angle, :asc)
      |> group_by_angle_delta()
      |> merge_similar_slope_lines()

    %TrendLine{
      lines: lines
    }
  end

  defp _create(lines, _, [], _), do: lines

  defp _create([], root, [p | points], mframe),
    do: _create([Line.new(mframe, root, p)], root, points, mframe)

  defp _create(lines, root, [p | points], mframe) do
    line = Line.new(mframe, root, p)

    #  crossed_on_next_frame?(root, p, mframe)
    with {:ok, line} <- is_line_worthless_still?(line, lines, p) do
      [line | lines]
    else
      _ -> lines
    end
    |> _create(root, points, mframe)
  end

  # Don't keep the line if it goes nowhere
  def is_line_worthless_still?(line, _, %{x: px}) do
    case elem(line.p2, 0) do
      ^px -> {:fail}
      _ -> {:ok, line}
    end
  end

  def group_by_angle_delta([]), do: []
  def group_by_angle_delta([line | lines]), do: group_by_angle_delta(lines, [[line]])

  def group_by_angle_delta([line1 | lines], [[line2 | rest] | groups]) do
    delta = abs(line1.angle - line2.angle)

    cond do
      delta < config(:min_angle_delta) ->
        group_by_angle_delta(lines, [[line1, line2 | rest] | groups])

      true ->
        group_by_angle_delta(lines, [[line1], [line2 | rest] | groups])
    end
  end

  def group_by_angle_delta([], groups), do: groups

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

  def angle_increased_enough?(line, [prev | _], %{type: type} = root) do
    delta = abs(line.angle - prev.angle)
    min_angle_delta = config(:min_angle_delta)

    # if root.frame.index == 265, do: IO.inspect(delta)

    cond do
      # If the angle has not changed enough
      delta < min_angle_delta ->
        cond do
          # Util.between?(Line.y_at(prev, root.frame.index), root.frame.open, root.frame.next.close) ->
          # {:ok, line}

          true ->
            {:fail}
        end

      (type === :top && line.slope > prev.slope) ||
          (type === :bottom && line.slope < prev.slope) ->
        {:ok, line}

      true ->
        {:ok, line}
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
