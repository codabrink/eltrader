defmodule Line do
  @derive [Poison.Encoder]
  @type top_bottom :: :top | :bottom
  defstruct [:point, :angle]

  @spec new(%Frame{}, %Frame{}, top_bottom) :: %Line{}
  def new(a, b, type) do
    case type do
      :top -> new({a.close_time, a.high}, {b.close_time, b.high})
      :bottom -> new({a.close_time, a.low}, {b.close_time, b.low})
    end
  end

  defp new({ax, ay}, {bx, by}) do
    %Line{
      angle: Topo.angle({ax, ay}, {bx, by}),
      point: %Geo.Point{coordinates: {ax, ay}}
    }
  end
end
