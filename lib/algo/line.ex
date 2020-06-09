defmodule Line do
  @derive {Poison.Encoder, except: [:body_cross, :stem_cross]}
  @type top_bottom :: :top | :bottom
  defstruct [
    :p1,
    :p2,
    :angle,
    :type,
    :p1_index,
    :p2_index,
    :length,
    :geom,
    :slope,
    :b,
    crosses: []
  ]

  def relevant_until(_, [], index), do: index

  def relevant_until(line, [frame | tail], index) do
    distance = Topo.distance(frame.stem_geom, line.geom)

    cond do
      abs(distance) < frame.close * 0.005 -> relevant_until(line, tail, frame.index)
      true -> relevant_until(line, tail, index)
    end
  end

  @spec new([%Frame{}], %Frame{}, %Geo.Point{}, %Geo.Point{}) :: %Line{}
  def new(frames, frame, p1, p2) do
    angle = Topo.angle(p1, p2)
    p2 = Topo.translate(p1, 20000.0, angle)
    slope = calc_slope(p1, p2)

    line = %Line{
      angle: angle,
      p1: p1,
      p2: p2,
      slope: slope,
      b: calc_b(p1, slope),
      geom: %Geo.LineString{coordinates: [p1.coordinates, p2.coordinates]},
      p1_index: frame.index
    }

    p2_index = relevant_until(line, frames, 0)
    frames_after = Enum.take(frames, frame.index - length(frames))

    %Line{
      line
      | p2: Topo.x_translate(p1, p2_index - frame.index, angle),
        p2_index: p2_index,
        crosses: Line.Cross.crosses(line, frames_after)
    }
  end

  # Calculate slope
  defp calc_slope(%{coordinates: {x1, y1}}, %{coordinates: {x2, y2}}), do: (y2 - y1) / (x2 - x1)
  # Used in the slope formula
  defp calc_b(%{coordinates: {x, y}}, m), do: y - m * x
  def y_at(line, x), do: line.slope * x + line.b
  def point_at(line, x), do: %Geo.Point{coordinates: {x, y_at(line, x)}}
end
