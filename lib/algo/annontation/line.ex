defmodule Line do
  @derive {Jason.Encoder, except: [:body_cross, :stem_cross]}
  @type top_bottom :: :top | :bottom
  defstruct [
    :p1,
    :p2,
    :angle,
    :type,
    :length,
    :geom,
    :slope,
    :b,
    :respect,
    crosses: [],
    source_frames: []
  ]

  def relevant_until(_, [], index), do: index

  def relevant_until(line, [frame | tail], index) do
    y = y_at(line, frame.index)
    distance = min(abs(y - frame.high), abs(y - frame.low))

    cond do
      distance < frame.close * 0.001 -> frame.index
      true -> relevant_until(line, tail, index)
    end
  end

  def new(frame, %Point{} = sp1, %Point{} = sp2) do
    angle = Topo.angle(sp1.coords, sp2.coords)
    slope = calc_slope(sp1.coords, sp2.coords)

    line = %Line{
      angle: angle,
      p1: sp1.coords,
      p2: sp2.coords,
      slope: slope,
      b: calc_b(sp1.coords, slope),
      source_frames: [sp1.frame, sp2.frame]
    }

    p2x = relevant_until(line, frame.before, 0)
    p2 = Topo.x_translate(sp1.coords, p2x - sp1.x, angle)

    line = %{
      line
      | p2: p2.coordinates,
        geom: %Geo.LineString{coordinates: [sp1.coords, p2.coordinates]}
    }

    %{
      line
      | crosses: Line.Cross.collect_crosses(line, frame.before),
        respect: calc_respect(line, frame)
    }
  end

  def calc_respect(line, frame) do
    %{p1: {p1x, _}} = line

    frame.points
    |> Enum.filter(fn %{coords: {x, _}} -> x > p1x end)
    |> Enum.filter(fn %{coords: {x, y}} ->
      Topo.distance(line.geom, {x, y}) < y * 0.01
    end)
    |> length()
  end

  # Calculate slope
  defp calc_slope({x1, y1}, {x2, y2}), do: (y2 - y1) / (x2 - x1)
  # Used in the slope formula
  defp calc_b({x, y}, m), do: y - m * x
  def y_at(line, x), do: line.slope * x + line.b
  def coords_at(line, x), do: {x, y_at(line, x)}
end
