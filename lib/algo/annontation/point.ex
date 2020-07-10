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
      percent: %R{
        range: 5..15,
        denominator: 100,
        value: 0.15
      }
    }

  def generate(mframe), do: generate(mframe.before, :dominion, config(:percent))

  def generate(frames, field, pct) do
    len = floor(pct * length(frames))

    bottom =
      Enum.sort_by(frames, fn f -> elem(Map.get(f, field), 0) end, :desc)
      |> Enum.slice(0..len)
      |> Enum.map(fn f -> {:bottom, f} end)

    top =
      Enum.sort_by(frames, fn f -> elem(Map.get(f, field), 1) end, :desc)
      |> Enum.slice(0..len)
      |> Enum.map(fn f -> {:top, f} end)

    (bottom ++ top)
    |> Enum.sort_by(&elem(&1, 1).index)
    |> _generate(%Payload{})
    |> Enum.reverse()
  end

  def _generate([], payload), do: payload.generated

  def _generate([{type, frame} | points], payload) do
    {_, payload} = create({type, frame}, payload)
    _generate(points, payload)
  end

  def create({type, frame}, payload) do
    {y, strength, prev_type} =
      case type do
        :bottom -> {frame.low, elem(frame.dominion, 0), :prev_bottom}
        :top -> {frame.high, elem(frame.dominion, 1), :prev_top}
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
