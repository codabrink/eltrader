defmodule Point do
  @ignore [:frame, :prev, :prev_top, :prev_bottom, :points_after_of_type, :points_after]
  @derive {Jason.Encoder, except: @ignore}
  @derive {Inspect, except: @ignore}

  defstruct [
    :type,
    :frame,
    :points_after,
    :points_after_of_type,
    :importance,
    :prev,
    :prev_bottom,
    :prev_top,
    :strength,
    :coords,
    :x,
    :y
  ]

  defmodule Refs do
    defstruct [:prev, :prev_top, :prev_bottom, generated: []]
  end

  defmodule Payload do
    defstruct [:all, :top, :bottom, :top_by_dominion, :bottom_by_dominion]
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
      Enum.sort_by(frames, &elem(Map.get(&1, field), 0), :desc)
      |> Enum.slice(0..len)
      |> Enum.map(fn f -> {:bottom, f} end)

    top =
      Enum.sort_by(frames, &elem(Map.get(&1, field), 1), :desc)
      |> Enum.slice(0..len)
      |> Enum.map(fn f -> {:top, f} end)

    points =
      (bottom ++ top)
      |> Enum.sort_by(&elem(&1, 1).index)
      |> _generate(%Refs{})
      |> Enum.reverse()

    top = Enum.filter(points, &(&1.type === :top))
    bottom = Enum.filter(points, &(&1.type === :bottom))

    %Payload{
      all: points,
      top: top,
      bottom: bottom,
      bottom_by_dominion: Enum.sort_by(bottom, &elem(&1.frame.dominion, 0), :desc),
      top_by_dominion: Enum.sort_by(top, &elem(&1.frame.dominion, 1), :desc)
    }
  end

  def _generate([], payload), do: payload.generated

  def _generate([{type, frame} | points], refs) do
    {_, refs} = create({type, frame}, refs)
    _generate(points, refs)
  end

  def create({type, frame}, refs) do
    {y, strength, prev_type} =
      case type do
        :bottom -> {frame.low, elem(frame.dominion, 0), :prev_bottom}
        :top -> {frame.high, elem(frame.dominion, 1), :prev_top}
      end

    points_after = Enum.reverse(refs.generated)

    point = %Point{
      frame: frame,
      x: frame.index,
      y: y,
      coords: {frame.index, y},
      strength: strength,
      prev_top: refs.prev_top,
      prev_bottom: refs.prev_bottom,
      prev: refs.prev,
      type: type,
      importance:
        case type do
          :bottom -> elem(frame.importance, 0)
          :top -> elem(frame.importance, 1)
        end,
      points_after: points_after,
      points_after_of_type: Enum.filter(points_after, &(&1.type === type))
    }

    {point,
     %{
       refs
       | prev_type => point,
         prev: point,
         generated: [point | refs.generated]
     }}
  end

  def move_right(point) do
    create({point.type, point.frame.next}, %Refs{
      prev: point.prev,
      prev_top: point.prev_top,
      prev_bottom: point.prev_bottom
    })
    |> elem(0)
  end
end
