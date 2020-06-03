defmodule Line do
  @derive [Poison.Encoder]
  @type top_bottom :: :top | :bottom
  defstruct [:point, :angle, :type, :frame_index]

  def new(%Frame{} = a, %Frame{} = b, type) do
    case type do
      :top -> new(type, a, {a.close_time, a.high}, {b.close_time, b.high})
      :bottom -> new(type, a, {a.close_time, a.low}, {b.close_time, b.low})
    end
  end

  def new(type, frame, p1, p2) do
    %Line{
      type: type,
      frame_index: frame.index,
      angle: Topo.angle(p1, p2),
      point: %Geo.Point{coordinates: p1}
    }
  end
end
