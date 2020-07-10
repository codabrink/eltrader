defmodule TrendLineRoot do
  def generate(mframe) do
    mframe.points
    |> Enum.sort_by(& &1.bottom_dominion)
  end
end
