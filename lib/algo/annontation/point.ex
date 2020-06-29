defmodule Point do
  @ignore [:frame, :prev, :prev_top, :prev_bottom, :points_after]
  @derive {Jason.Encoder, except: @ignore}
  @derive {Inspect, except: @ignore}

  defstruct [:frame, :points_after, :prev, :prev_bottom, :prev_top, :strength, :coords, :x, :y]

  use Configurable,
    config: %{
      population: %R{
        range: 5..15,
        value: 10
      }
    }

  def generate(frame, population \\ nil) do
    frames = frame.before
    population = floor(population || config(:population) / 100 * length(frames))

    bottom_points =
      frames
      |> Enum.sort(fn f1, f2 -> f1.bottom_dominion >= f2.bottom_dominion end)
      |> Enum.slice(0..population)
      |> Enum.map(fn f -> {:bottom, f} end)

    top_points =
      frames
      |> Enum.sort(fn f1, f2 -> f1.top_dominion >= f2.top_dominion end)
      |> Enum.slice(0..population)
      |> Enum.map(fn f -> {:top, f} end)

    (bottom_points ++ top_points)
    |> Enum.sort(fn {_, f1}, {_, f2} -> f1.open_time <= f2.open_time end)
    |> _generate([[], [], []])
    |> Enum.map(&Enum.reverse/1)
  end

  defp _generate([], l), do: l

  defp _generate([{:bottom, frame} | points], [all, bottom, top]) do
    sp = %Point{
      frame: frame,
      x: frame.index,
      y: frame.low,
      coords: {frame.index, frame.low},
      strength: frame.bottom_dominion,
      prev_top: List.first(top),
      prev_bottom: List.first(bottom),
      prev: List.first(all)
    }

    _generate(points, [[sp | all], [sp | bottom], top])
  end

  defp _generate([{:top, frame} | points], [all, bottom, top]) do
    sp = %Point{
      frame: frame,
      x: frame.index,
      y: frame.high,
      coords: {frame.index, frame.high},
      strength: frame.top_dominion,
      prev_top: List.first(top),
      prev_bottom: List.first(bottom),
      prev: List.first(all)
    }

    _generate(points, [[sp | all], bottom, [sp | top]])
  end
end
