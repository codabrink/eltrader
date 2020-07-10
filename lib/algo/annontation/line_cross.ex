defmodule Line.Cross do
  @derive Jason.Encoder
  # @cross_min_gap 1
  @break_min_distance 0.0001
  @type cross_type :: :up | :down | :bounce | :reject
  defstruct [
    :prev,
    :line,
    :did_break,
    :width,
    :depth,
    :frames,
    :open_coords,
    :close_coords,
    :type
  ]

  def collect_crosses(line, frames), do: _collect_crosses(line, frames, [])
  defp _collect_crosses(_, [], crosses), do: crosses

  # ignore the crosses that happened before the line was created
  defp _collect_crosses(%{source_frames: [_, %{index: i1}]}, [%{index: i2} | _], crosses)
       when i2 <= i1,
       do: crosses

  defp _collect_crosses(line, [frame | tail], crosses) do
    dist = Topo.distance(line.geom, frame.stem_geom)
    tolerance = frame.close * @break_min_distance

    cond do
      frame in line.source_frames -> _collect_crosses(line, tail, crosses)
      dist <= tolerance -> collect_crossing_frames(line, tail, [frame], crosses)
      true -> _collect_crosses(line, tail, crosses)
    end
  end

  def collect_crossing_frames(line, [], crossing_frames, crosses),
    do: _collect_crosses(line, [], [create(line, crossing_frames) | crosses])

  def collect_crossing_frames(line, [frame | tail], crossing_frames, crosses) do
    tolerance = frame.close * @break_min_distance
    distance = Topo.distance(line.geom, frame.stem_geom)

    cond do
      distance <= tolerance ->
        collect_crossing_frames(line, tail, [frame | crossing_frames], crosses)

      true ->
        crossing_frames = Enum.reverse(crossing_frames)
        _collect_crosses(line, tail, [create(line, crossing_frames) | crosses])
    end
  end

  def create(line, crossing_frames) do
    %Line.Cross{
      frames: crossing_frames,
      open_coords: Line.coords_at(line, List.last(crossing_frames).index),
      close_coords: Line.coords_at(line, List.first(crossing_frames).index),
      type: cross_type(line, crossing_frames),
      width: length(crossing_frames),
      depth: calc_depth(line, crossing_frames, {0, 0})
    }
  end

  @spec cross_type(%Line{}, [%Frame{}]) :: cross_type
  def cross_type(line, crossing_frames) do
    first = List.first(crossing_frames)
    last = List.last(crossing_frames)

    open = last.open - Line.y_at(line, last.index)
    close = first.close - Line.y_at(line, first.index)

    cond do
      open <= 0 && close <= 0 -> :reject
      open <= 0 && close > 0 -> :up
      open > 0 && close <= 0 -> :down
      open > 0 && close > 0 -> :bounce
    end
  end

  def calc_depth(_, [], val), do: val

  def calc_depth(line, [frame | frames], {max, min}) do
    %{high: high, low: low} = frame
    line_y = Line.y_at(line, frame.index)
    calc_depth(line, frames, {max(max, high - line_y), min(min, low - line_y)})
  end

  def all?(el), do: Enum.all?(el, &is?/1)
  def is?(%Line.Cross{}), do: true
  def is?(_), do: false
end
