defmodule Frame do
  @ignore [:body_geom, :stem_geom, :before, :after, :next, :prev]
  @derive {Jason.Encoder, except: @ignore}
  @derive {Inspect, except: @ignore}

  use Configurable,
    config: %{}

  defstruct [
    :open_time,
    :open,
    :high,
    :low,
    :close,
    :all,
    :price_average,
    :volume,
    :asset_volume,
    :close_time,
    :num_trades,
    :body_geom,
    :stem_geom,
    :index,
    :momentum,
    :prev,
    :next,
    :dominion,
    :importance,
    :stake,
    :rsi_14,
    :points,
    :_before,
    :_after,
    before: [],
    after: [],
    trend_lines: [],
    votes: []
  ]

  def new(frame, prev, index, _opts) do
    price_average = (frame.open + frame.high + frame.low + frame.close) / 4.0

    %Frame{
      frame
      | prev: prev,
        index: index,
        price_average: price_average,
        momentum: calculate_momentum(frame, prev, index),
        body_geom: %Geo.LineString{coordinates: [{index, frame.open}, {index, frame.close}]},
        stem_geom: %Geo.LineString{coordinates: [{index, frame.high}, {index, frame.low}]}
    }
  end

  def complete([]), do: []
  def complete([frame]), do: [complete(frame)]

  def complete([frame | frames]) do
    [frame | complete(frames)]
  end

  def complete(frame) do
    IO.puts("Completing frame #{frame.index}...")

    {time, frame} = :timer.tc(fn -> generate_points(frame) end)
    IO.puts("#{time}: Time to generate points")
    {time, frame} = :timer.tc(fn -> add_trend_lines(frame) end)
    IO.puts("#{time}: Time to generate trend lines")
    {time, frame} = :timer.tc(fn -> add_rsi(frame, 14) end)
    IO.puts("#{time}: Time to generate RSI")

    %{frame | _before: frame.before, _after: frame.after}
  end

  def add_rsi(frame, width) do
    %{frame | rsi_14: Indicators.RSI.calculate(frame, width)}
  end

  def generate_points(frame) do
    with {:ok, points} <- Point.generate(frame),
         {:ok, strong_points} <- StrongPoint.generate(points) do
      TestUtil.is_sorted(points, & &1.x)

      %{
        frame
        | points:
            Point.link(points, strong_points, {[], []})
            |> Point.group()
      }
    end
  end

  def add_trend_lines(frame) do
    %{frame | trend_lines: TrendLine.generate(frame)}
  end

  def add_votes(frame) do
    votes =
      [Decision.TrendReclaim, Decision.TrendBreak]
      |> Enum.reduce([], fn d, acc -> acc ++ apply(d, :run, [frame]) end)

    %{frame | votes: votes}
  end

  def calculate_momentum(candle, prev, index) do
    find_frame(prev, index - C.fetch(:momentum_width))
    |> case do
      nil -> 0
      f -> candle.close - f.open
    end
  end

  def find_frame(nil, _), do: nil

  def find_frame(frame, index) do
    case frame.index do
      ^index -> frame
      _ -> find_frame(frame.prev, index)
    end
  end

  def surrounding(frames, index, n) do
    Enum.slice(frames, Enum.max([index - n, 0]), n * 2 + 1)
  end

  def dominion([], _), do: []

  def dominion([frame | frames], mframe) do
    db = dominion(frame.low, frame.before, frame.after, :bottom, 0)
    dt = dominion(frame.high, frame.before, frame.after, :top, 0)
    recentness = frame.index / mframe.index * 7

    [
      %Frame{
        frame
        | dominion: {db, dt},
          importance: {db + recentness, dt + recentness}
      }
      | dominion(frames, mframe)
    ]
  end

  def dominion(y, _, [%{high: ny} | _], _, dist) when y === ny, do: dist

  def dominion(y, [%{high: py} | _], [%{high: ny} | _], :top, dist) when py > y or ny > y,
    do: dist

  def dominion(y, [%{low: py} | _], [%{low: ny} | _], :bottom, dist) when py < y or ny < y,
    do: dist

  def dominion(y, [_ | ptail], [_ | ntail], type, dist),
    do: dominion(y, ptail, ntail, type, dist + 1)

  def dominion(_, _, _, _, dist), do: dist
end
