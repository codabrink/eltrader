defmodule Point do
  @ignore [:frame, :prev, :prev_top, :prev_bottom, :points_after, :all_points_after]
  @derive {Jason.Encoder, except: @ignore}
  @derive {Inspect, except: @ignore}

  defstruct [
    :type,
    :frame,
    :points_after,
    :all_points_after,
    :prev,
    :prev_bottom,
    :prev_top,
    :strength,
    :coords,
    :x,
    :y
  ]

  defmodule Payload do
    defstruct [:prev, :prev_top, :prev_bottom, generated: []]
  end

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
    |> _generate(%Payload{})
    |> Enum.reverse()
  end

  defp _generate([], payload), do: payload.generated

  defp _generate([{type, frame} | points], payload) do
    {_, payload} = create({type, frame}, payload)
    _generate(points, payload)
  end

  def create({type, frame}, payload) do
    {y, strength, prev_type} =
      case type do
        :bottom -> {frame.low, frame.bottom_dominion, :prev_bottom}
        :top -> {frame.high, frame.top_dominion, :prev_top}
      end

    point = %Point{
      frame: frame,
      x: frame.index,
      y: y,
      coords: {frame.index, y},
      strength: strength,
      prev_top: payload.prev_top,
      prev_bottom: payload.prev_bottom,
      prev: payload.prev,
      type: type
    }

    {point,
     %{
       payload
       | prev_type => point,
         prev: point,
         generated: [point | payload.generated]
     }}
  end

  def move_right(point) do
    create({point.type, point.frame.next}, %Payload{
      prev: point.prev,
      prev_top: point.prev_top,
      prev_bottom: point.prev_bottom
    })
    |> elem(0)
  end
end
