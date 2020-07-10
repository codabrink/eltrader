defmodule TrendLine do
  @derive Jason.Encoder
  use Configurable,
    config: %{
      min_slope_delta: %R{
        value: fn y -> y / 20000 end
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

  def create(%Point{points_after: points} = sp, mframe) do
    %TrendLine{
      lines: _create([], sp, Enum.take(points, 15), mframe)
    }
  end

  defp _create(lines, _, [], _), do: lines

  defp _create([], sp, [p | points], mframe),
    do: _create([Line.new(mframe, sp, p)], sp, points, mframe)

  defp _create(lines, sp, [p | points], mframe) do
    [Line.new(mframe, sp, p) | lines]
    |> slope_increased_enough?(sp)
    |> crossed_on_next_frame?(sp, p, mframe)
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

  def slope_increased_enough?([line, prev | lines], %{type: type} = sp) do
    delta = abs(line.slope - prev.slope)
    min_slope_delta = config(:min_slope_delta).(elem(line.p1, 1))

    cond do
      # If the angle has not changed enough
      delta < min_slope_delta ->
        cond do
          Util.between?(Line.y_at(prev, sp.frame.index), sp.frame.open, sp.frame.next.close) ->
            [line | lines]

          # closed_on?(prev, sp.frame) ->
          true ->
            [prev | lines]
        end

      (type === :top && line.slope > prev.slope) ||
          (type === :bottom && line.slope < prev.slope) ->
        [line, prev | lines]

      true ->
        [prev | lines]
    end
  end

  defp crossed_on_next_frame?([line | lines], sp, p, mframe) do
    cond do
      closed_on?(line, sp.frame.next) ->
        sp = Point.move_right(sp)
        crossed_on_next_frame?([Line.new(mframe, sp, p) | lines], sp, p, mframe)

      closed_on?(line, p.frame.next) ->
        p = Point.move_right(p)
        crossed_on_next_frame?([Line.new(mframe, sp, p) | lines], sp, p, mframe)

      true ->
        [line | lines]
    end
  end

  defp closed_on?(_, nil), do: false

  defp closed_on?(line, frame) do
    Util.between?(Line.y_at(line, frame.index), frame.open, frame.close)
  end
end
