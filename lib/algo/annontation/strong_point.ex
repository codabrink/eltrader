defmodule StrongPoint do
  use Configurable,
    config: %{
      percent: %R{
        range: 1..10,
        denominator: 100,
        value: 0.02
      }
    }

  def generate(mframe),
    do: Point.generate(mframe.before, :importance, config(:percent)) |> _generate(mframe.points)

  defp _generate([], _), do: []

  defp _generate([sp | strong_points], points_after) do
    points_after = points_after(sp.x, points_after)

    [
      %{
        sp
        | all_points_after: points_after,
          points_after: Enum.filter(points_after, &(&1.type === sp.type))
      }
      | _generate(strong_points, points_after)
    ]
  end

  def points_after(x1, [%{x: x2} | points]) when x1 >= x2,
    do: points_after(x1, points)

  def points_after(_, points), do: points
end
