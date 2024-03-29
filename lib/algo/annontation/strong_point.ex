defmodule StrongPoint do
  use Configurable,
    config: %{
      percent: %R{
        range: 1..10,
        denominator: 100,
        value: 0.04
      }
    }

  def generate(points) do
    TestUtil.is_sorted(points, & &1.x)

    bottom_points =
      Enum.filter(points, &(&1.type === :bottom))
      |> Enum.sort_by(&elem(&1.frame.dominion, 0), :desc)
      |> Enum.take(floor(config(:percent) * length(points)))

    top_points =
      Enum.filter(points, &(&1.type === :top))
      |> Enum.sort_by(&elem(&1.frame.dominion, 1), :desc)
      |> Enum.take(floor(config(:percent) * length(points)))

    (bottom_points ++ top_points)
    |> Enum.sort_by(& &1.x)
    |> (&{:ok, &1}).()
  end
end
