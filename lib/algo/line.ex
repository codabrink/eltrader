defmodule Line do
  @derive [Poison.Encoder]
  @type top_bottom :: :top | :bottom
  defstruct [:p1, :p2, :angle, :type, :p1_index, :p2_index, :length, :geom]

  def relevant_until([], _, index), do: index

  def relevant_until([frame | tail], line, index) do
    distance = Topo.distance(frame.stem_geom, line.geom)

    cond do
      abs(distance) < 50 -> relevant_until(tail, line, frame.index)
      true -> relevant_until(tail, line, index)
    end
  end

  @spec new([%Frame{}], %Frame{}, %Geo.Point{}, %Geo.Point{}) :: %Line{}
  def new(frames, frame, p1, p2) do
    angle = Topo.angle(p1, p2)
    p2 = Topo.translate(p1, 20000.0, angle)

    line = %Line{
      angle: angle,
      p1: p1,
      p2: p2,
      geom: %Geo.LineString{coordinates: [p1.coordinates, p2.coordinates]},
      p1_index: frame.index
    }

    p2_index = relevant_until(frames, line, 0)

    %Line{
      line
      | p2: Topo.x_translate(p1, p2_index - frame.index, angle),
        p2_index: p2_index
    }
  end
end
