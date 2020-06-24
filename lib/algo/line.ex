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
      distance < frame.close * 0.01 -> relevant_until(line, tail, frame.index)
      true -> relevant_until(line, tail, index)
    end
  end

  @spec new(%Frame{}, %StrongPoint{}, %StrongPoint{}) :: %Line{}
  def new(frame, sp1, sp2) do
    angle = Topo.angle(sp1.point, sp2.point)
    slope = calc_slope(sp1.point, sp2.point)

    %{coordinates: {p1x, _}} = sp1.point

    line = %Line{
      angle: angle,
      p1: sp1.point,
      p2: sp2.point,
      slope: slope,
      b: calc_b(sp1.point, slope),
      source_frames: [sp1.frame, sp2.frame]
    }

    p2x = relevant_until(line, frame.frames, 0)
    frames_after = Enum.take(frame.frames, p1x - frame.index)
    p2 = Topo.x_translate(sp1.point, p2x - p1x, angle)

    line = %{
      line
      | p2: p2,
        geom: %Geo.LineString{coordinates: [sp1.point.coordinates, p2.coordinates]}
    }

    %{
      line
      | crosses: Line.Cross.collect_crosses(line, frames_after),
        respect: calc_respect(line, frame)
    }
  end

  def calc_respect(line, frame) do
    %{p1: %{coordinates: {p1x, _}}} = line

    frame.strong_points
    |> elem(0)
    |> Enum.filter(fn %{point: %{coordinates: {x, _}}} -> x > p1x end)
    |> Enum.filter(fn %{point: %{coordinates: {x, y}}} ->
      Topo.distance(line.geom, {x, y}) < y * 0.01
    end)
    |> length()
  end

  # Calculate slope
  defp calc_slope(%{coordinates: {x1, y1}}, %{coordinates: {x2, y2}}), do: (y2 - y1) / (x2 - x1)
  # Used in the slope formula
  defp calc_b(%{coordinates: {x, y}}, m), do: y - m * x
  def y_at(line, x), do: line.slope * x + line.b
  def point_at(line, x), do: %Geo.Point{coordinates: {x, y_at(line, x)}}
end
