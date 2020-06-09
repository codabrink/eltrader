defmodule Line.Cross do
  # @cross_min_gap 1
  @break_min_distance 0.0001
  @type cross_type :: :up | :down | :bounce | :reject
  defstruct [:prev, :line, :did_break, :width, :frames, :open_point, :close_point]

  def crosses(line, frames), do: crosses(line, frames, [])
  def crosses(_, [], crosses), do: crosses

  def crosses(line, [frame | tail], crosses) do
    dist = Topo.distance(frame.stem_geom, line.geom)

    case dist do
      0.0 -> collect_frames(line, tail, [frame], crosses)
      _ -> crosses(line, tail, crosses)
    end
  end

  def collect_frames(line, [frame | tail], crossing_frames, crosses) do
    tolerance = frame.close * @break_min_distance

    case Topo.distance(line.geom, frame.stem_geom) do
      0.0 ->
        collect_frames(line, tail, [frame | crossing_frames], crosses)

      x when x < tolerance ->
        collect_frames(line, tail, [frame | crossing_frames], crosses)

      _ ->
        [_ | tail] = tail

        crosses(line, tail, [
          %Line.Cross{
            frames: crossing_frames,
            open_point: Line.point_at(line, List.first(crossing_frames).index),
            close_point: Line.point_at(line, List.last(crossing_frames).index)
          }
          | crosses
        ])
    end
  end
end
