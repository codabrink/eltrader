defmodule Candles do
  defmodule CandleGroup do
    use TypedStruct

    typedstruct do
      field :k, Range
      field :candles, [%Candle{}]
    end
  end

  def init_cache(symbol, interval) do
    candles =
      File.read!(file_path(symbol, interval))
      |> Jason.decode!(%{keys: :atoms!})
      |> Enum.map(&Candle.new/1)

    step = get_step(interval)

    candles =
      List.Helper.group_adjacent_fn(candles, fn a, b -> b.open_time - a.open_time <= step end)

    cache =
      Enum.map(candles, fn group ->
        %CandleGroup{
          k: Range.new(List.first(group).open_time, List.last(group).open_time),
          candles: group
        }
      end)

    Trader.Cache.set(cache_key(symbol, interval), cache)
  end

  def save_cache(cache, symbol, interval) do
    {:ok, file} = File.open(file_path(symbol, interval), [:write])

    cache
    |> Enum.map(& &1.candles)
    |> Jason.encode!()
    |> (&IO.binwrite(file, &1)).()

    File.close(file)
  end

  def cache_candles(candles, symbol, interval) do
    range = Range.new(List.first(candles).open_time, List.last(candles).open_time)

    cache = [
      %CandleGroup{k: range, candles: candles}
      | Trader.Cache.get(cache_key(symbol, interval)) || []
    ]

    for g1 <- cache, g2 <- cache do
      cond do
        Range.disjoint?(g1.k, g2.k) -> [g1, g2]
        true -> merge_groups(g1, g2)
      end
    end
    |> List.flatten()
    |> save_cache(symbol, interval)
  end

  def merge_groups(%{k: f1..l1, candles: c1}, %{k: f2..l2, candles: c2}),
    do: %CandleGroup{
      k: Range.new(min(f1, f2), max(l1, l2)),
      candles: (c1 ++ c2) |> Enum.uniq() |> Enum.sort_by(& &1.open_time)
    }

  def download_candles(symbol, interval, start_ms, end_ms) do
    start_ms = start_ms + 0.0
    end_ms = end_ms + 0.0

    url =
      "https://api.binance.com/api/v3/klines?" <>
        "symbol=#{symbol}" <>
        "&interval=#{interval}" <>
        "&startTime=#{:erlang.float_to_binary(start_ms, decimals: 0)}" <>
        "&endTime=#{:erlang.float_to_binary(end_ms, decimals: 0)}"

    HTTPoison.get(url)
    |> case do
      {:ok, response} -> response.body
    end
    |> Jason.decode!(%{keys: :atoms!})
    |> Enum.map(&Candle.new/1)
  end

  def candles(symbol, interval),
    do: candles(symbol, interval, Timex.beginning_of_day(DateTime.utc_now()))

  def candles(symbol, interval, end_time),
    do: candles(symbol, interval, Timex.shift(end_time, days: -5), end_time)

  def candles(symbol, interval, start_time, end_time) do
    candle_ranges = Trader.Cache.get(cache_key(symbol, interval)) || []
    {start_ms, end_ms} = to_ms(start_time, end_time)
    step = get_step(interval)
    open_times = Range.Helper.to_list(start_ms..end_ms, step)

    missing = List.Helper.subtract(open_times, Enum.map(candle_ranges, & &1.k))

    for group <- List.Helper.group_adjacent(missing, step) do
      start_ms = List.first(group)
      end_ms = List.last(group)

      download_candles(symbol, interval, start_ms, end_ms)
      |> cache_candles(symbol, interval)
    end
  end

  def candles_json(symbol, interval, start_time, end_time) do
    candles(symbol, interval, start_time, end_time)
    |> Jason.encode!()
  end

  def file_path(symbol, interval) do
    unless File.exists?(Path.dirname("cache")), do: File.mkdir_p!(Path.dirname("cache"))

    Path.join("cache", "#{symbol}-#{interval}.json")
  end

  def to_ms(s, e), do: {DateTime.to_unix(s, :millisecond), DateTime.to_unix(e, :millisecond)}

  def cache_key(symbol, interval), do: "#{symbol}_#{interval}"
  def get_step(interval), do: _get_step(Regex.run(~r{(\d+)([a-zA-Z])}, interval))

  defp _get_step([_, n, u]) do
    case [String.to_integer(n), u] do
      [n, "m"] -> Timex.Duration.from_minutes(n)
      [n, "h"] -> Timex.Duration.from_hours(n)
      [n, "d"] -> Timex.Duration.from_days(n)
      [n, "w"] -> Timex.Duration.from_weeks(n)
      _ -> Timex.Duration.from_days(1)
    end
    |> Timex.Duration.to_milliseconds()
  end

  defp _get_step(_), do: nil
end
