defmodule Frame do
  @ignore [:body_geom, :stem_geom, :before, :after, :next, :prev]
  @derive {Jason.Encoder, except: @ignore}
  @derive {Inspect, except: @ignore}

  use Configurable,
    config: %{
      frame_width: %R{
        range: 100..300,
        value: 100
      }
    }

  defstruct [
    :open_time,
    :open,
    :high,
    :low,
    :close,
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
    :bottom_dominion,
    :top_dominion,
    :stake,
    :rsi_14,
    before: [],
    after: [],
    points: [],
    trend_lines: [],
    strong_points: [],
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
  def complete([frame | frames]), do: [frame | complete(frames)]

  def complete(frame) do
    frame
    |> generate_points()
    |> generate_strong_points()
    |> add_trend_lines()
    |> add_rsi(14)
  end

  def add_rsi(frame, width) do
    %{frame | rsi_14: Indicators.RSI.calculate(frame, width)}
  end

  def generate_points(frame) do
    %{frame | points: Point.generate(frame)}
  end

  def generate_strong_points(frame) do
    %{frame | strong_points: StrongPoint.generate(frame)}
  end

  def add_trend_lines(frame) do
    %{frame | trend_lines: TrendLine.generate(frame)}
  end

  @spec add_votes(%Frame{}) :: %Frame{}
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

  def merge_dominion(frames), do: merge_dominion(frames, frames)
  def merge_dominion([], _), do: []

  def merge_dominion([frame | tail], frames) do
    {first, last} = Util.split_around(frames, frame.index)

    [
      %Frame{
        frame
        | top_dominion: peak_dominion(frame, {first, last}, :top, 0),
          bottom_dominion: peak_dominion(frame, {first, last}, :bottom, 0)
      }
      | merge_dominion(tail, frames)
    ]
  end

  def peak_dominion(_, {[], []}, _, dist), do: dist

  def peak_dominion(frame, {first, last}, type, dist) do
    {f, first_tail} = safe_match(first)
    {l, last_tail} = safe_match(last)

    cond do
      peak_defeated(type, frame, f) || peak_defeated(type, frame, l) -> dist
      true -> peak_dominion(frame, {first_tail, last_tail}, type, dist + 1)
    end
  end

  defp peak_defeated(_, _, nil), do: false
  defp peak_defeated(:top, frame, f), do: f.high > frame.high
  defp peak_defeated(:bottom, frame, f), do: f.low < frame.low

  defp safe_match([]), do: {nil, []}
  defp safe_match([head | tail]), do: {head, tail}
end
