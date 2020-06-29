defmodule StrongPoint do
  use Configurable,
    config: %{
      population: %R{
        range: 1..10,
        value: 1
      }
    }

  def generate(frame) do
    frame
    |> Point.generate(config(:population))
    |> Enum.map(fn points -> points_after(points, frame) end)
  end

  def points_after([], _), do: []

  def points_after([point | points], frame) do
    {all, _, _} = frame.points
    [%{point | points_after: points_after(point.x, all)} | points_after(points, frame)]
  end

  def points_after(x1, [%{x: x2} | points]) when x1 >= x2,
    do: points_after(x1, points)

  def points_after(_, points), do: points
end
