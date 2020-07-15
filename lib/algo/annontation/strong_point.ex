defmodule StrongPoint do
  use Configurable,
    config: %{
      percent: %R{
        range: 1..10,
        denominator: 100,
        value: 0.1
      }
    }

  def generate(points) do
    TestUtil.is_sorted(points, & &1.x)

    Enum.sort_by(points, & &1.frame.dominion, :desc)
    |> Enum.take(floor(config(:percent) * length(points)))
    |> Enum.sort_by(& &1.x)
    |> (&{:ok, &1}).()
  end
end
