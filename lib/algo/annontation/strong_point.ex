defmodule StrongPoint do
  use Configurable,
    config: %{
      population: %R{
        range: 1..10,
        value: 3
      }
    }

  def generate(frame) do
    Point.generate(frame, config(:population))
    |> generate(frame.points)
  end

  def generate([], _), do: []

  def generate([sp | strong_points], points_after) do
    points_after = points_after(sp.x, points_after)

    [
      %{
        sp
        | all_points_after: points_after,
          points_after: Enum.filter(points_after, &(&1.type === sp.type))
      }
      | generate(strong_points, points_after)
    ]
  end

  def points_after(x1, [%{x: x2} | points]) when x1 >= x2,
    do: points_after(x1, points)

  def points_after(_, points), do: points
end
