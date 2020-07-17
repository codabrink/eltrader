defmodule Point do
  @ignore [:frame, :prev, :prev_top, :prev_bottom, :points_after_of_type, :points_after]
  @derive {Jason.Encoder, except: @ignore}
  @derive {Inspect, except: @ignore}

  use Configurable,
    config: %{
      percent: %R{
        range: 5..15,
        denominator: 100,
        value: 0.09
      }
    }

  defstruct [
    :type,
    :frame,
    :points_after,
    :points_after_of_type,
    :strong_points_after,
    :strong_points_after_of_type,
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
    defstruct [:prev, :prev_top, :prev_bottom, :points, generated: []]
  end

  defmodule Payload do
    @derive Jason.Encoder
    defstruct [:all, :top, :bottom, :top_by_dominion, :bottom_by_dominion]
  end

  def generate(mframe), do: generate(mframe.before, :dominion, config(:percent))

  def generate(frames, field, pct) do
    len = floor(pct * length(frames))

    bottom =
      Enum.sort_by(frames, &elem(Map.get(&1, field), 0), :desc)
      |> Enum.take(len)
      |> Enum.map(fn f -> {:bottom, f} end)

    top =
      Enum.sort_by(frames, &elem(Map.get(&1, field), 1), :desc)
      |> Enum.take(len)
      |> Enum.map(fn f -> {:top, f} end)

    (bottom ++ top)
    |> Enum.sort_by(&elem(&1, 1).index)
    |> _generate()
    |> (&{:ok, &1}).()
  end

  def _generate([]), do: []
  def _generate([point | points]), do: [create(point) | _generate(points)]

  def create({type, frame}) do
    {y, strength} =
      case type do
        :bottom -> {frame.low, elem(frame.dominion, 0)}
        :top -> {frame.high, elem(frame.dominion, 1)}
      end

    %Point{
      frame: frame,
      x: frame.index,
      y: y,
      coords: {frame.index, y},
      strength: strength,
      type: type,
      importance:
        case type do
          :bottom -> elem(frame.dominion, 0)
          :top -> elem(frame.dominion, 1)
        end
    }
  end

  def move_right(point), do: create({point.type, point.frame.next})

  def points_after([%{x: x} | points], x2) when x2 > x, do: points_after(points, x2)
  def points_after(points, _), do: points

  def link_point(p, points, strong_points) do
    %{
      p
      | points_after: points,
        points_after_of_type: Enum.filter(points, &(&1.type === p.type)),
        strong_points_after: strong_points,
        strong_points_after_of_type: Enum.filter(strong_points, &(&1.type === p.type))
    }
  end

  def link(
        [%{x: x1} = point | points],
        [%{x: x2} = strong_point | strong_points],
        {linked_points, linked_strong_points}
      ) do
    {strong_points, linked_strong_points} =
      cond do
        x1 < x2 ->
          {[strong_point | strong_points], linked_strong_points}

        true ->
          {strong_points,
           [link_point(strong_point, points, strong_points) | linked_strong_points]}
      end

    link(
      points,
      strong_points,
      {[link_point(point, points, strong_points) | linked_points], linked_strong_points}
    )
  end

  def link([point | points], [], {linked_points, linked_strong_points}),
    do: link(points, [], {[link_point(point, points, []) | linked_points], linked_strong_points})

  def link(_, _, {linked_points, linked_strong_points}) do
    TestUtil.is_sorted(linked_points, & &1.x, :desc)
    TestUtil.is_sorted(linked_strong_points, & &1.x, :desc)

    %{
      all: Enum.reverse(linked_points),
      strong: Enum.reverse(linked_strong_points)
    }
  end

  def group(%{all: all, strong: strong}) do
    exclusive = all -- strong

    %{
      all: %Payload{
        all: all,
        top: Enum.filter(all, &(&1.type === :top)),
        bottom: Enum.filter(all, &(&1.type === :bottom))
      },
      strong: %Payload{
        all: strong,
        top: Enum.filter(strong, &(&1.type === :top)),
        bottom: Enum.filter(strong, &(&1.type === :bottom))
      },
      exclusive: %Payload{
        all: exclusive
      }
    }
  end
end
