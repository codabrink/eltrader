defmodule Line.Cross do
  # @cross_min_gap 1
  # @break_min_distance 0.0001
  @type cross_type :: :up | :down | :bounce | :reject
  defstruct [:prev, :line, :did_break, :width, :frames, :open_point, :close_point, :type]

  def crosses(line, frames), do: crosses(line, frames, [])
  def crosses(_, [], crosses), do: crosses

  def crosses(line, [frame | tail], crosses) do
    dist = Topo.distance(line.geom, frame.stem_geom)
    # frame.close * @break_min_distance
    tolerance = 0.0

    cond do
      frame in line.source_frames -> crosses(line, tail, crosses)
      dist <= tolerance -> collect_crossing_frames(line, tail, [frame], crosses)
      true -> crosses(line, tail, crosses)
    end
  end

  @spec collect_crossing_frames(%Line{}, [%Frame{}], [%Frame{}], [%Line.Cross{}]) ::
          [%Line.Cross{}]
  def collect_crossing_frames(line, [frame | tail], crossing_frames, crosses) do
    # frame.close * @break_min_distance
    tolerance = 0.0
    distance = Topo.distance(line.geom, frame.stem_geom)

    cond do
      distance <= tolerance ->
        collect_crossing_frames(line, tail, [frame | crossing_frames], crosses)

      true ->
        crossing_frames = Enum.reverse(crossing_frames)
        crosses(line, tail, [create(line, crossing_frames) | crosses])
    end
  end

  def create(line, crossing_frames) do
    %Line.Cross{
      frames: crossing_frames,
      open_point: Line.point_at(line, List.first(crossing_frames).index),
      close_point: Line.point_at(line, List.last(crossing_frames).index),
      type: cross_type(line, crossing_frames),
      width: length(crossing_frames)
    }
  end

  @spec cross_type(%Line{}, [%Frame{}]) :: cross_type
  def cross_type(line, crossing_frames) do
    first = List.first(crossing_frames)
    last = List.last(crossing_frames)

    open = first.open - Line.y_at(line, first.index)
    close = last.close - Line.y_at(line, last.index)

    cond do
      open <= 0 && close <= 0 -> :reject
      open <= 0 && close > 0 -> :up
      open > 0 && close <= 0 -> :down
      open > 0 && close > 0 -> :bounce
    end
  end
end
