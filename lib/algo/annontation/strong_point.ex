defmodule StrongPoint do
  use Configurable,
    config: %{
      percent: %R{
        range: 1..10,
        denominator: 100,
        value: 0.01
      }
    }

  def generate(mframe),
    do: Point.generate(mframe.before, :importance, config(:percent))
end
