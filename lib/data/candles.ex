defmodule Candles do
  import Util

  defmodule CandleGroup do
    use TypedStruct

    typedstruct do
      field :k, Range
      field :candles, [%Frame{}]
    end
  end

  defp cache(symbol, interval) do
    unless Cache.has_key?(cache_key(symbol, interval)), do: read_cache_from_disk(symbol, interval)
    Cache.get(cache_key(symbol, interval)) || []
  end

  defp read_cache_from_disk(symbol, interval) do
    read_candles_from_disk(symbol, interval)
    |> Enum.map(fn group ->
      %CandleGroup{
        k: Range.new(List.first(group).open_time, List.last(group).open_time),
        candles: group
      }
    end)
    |> (&Cache.set(cache_key(symbol, interval), &1)).()
  end

  defp write_cache_to_disk(cache, symbol, interval),
    do: Enum.map(cache, & &1.candles) |> write_candles_to_disk(symbol, interval)

  defp write_candles_to_disk(candles, symbol, interval) do
    IO.puts("Writing candles to disk...")
    file = File.open!(file_path(symbol, interval), [:write])
    candles |> Jason.encode!() |> (&IO.binwrite(file, &1)).()
    IO.puts("Closing file...")
    File.close(file)
  end

  defp read_candles_from_disk(symbol, interval) do
    try do
      File.read!(file_path(symbol, interval))
      |> Jason.decode!(%{keys: :atoms!})
      |> Enum.map(fn g -> Enum.map(g, &Candle.new/1) end)
    rescue
      _ -> []
    end
  end

  def build_cache() do
    ["5m", "15m", "30m", "1h"]
    |> Enum.map(fn t -> build_cache("BTCUSDT", t) end)
  end

  def build_cache(symbol, interval) do
    IO.puts("Building cache for #{symbol}, #{interval}...")
    step = to_ms(interval)

    end_time = DateTime.utc_now()
    start_time = Timex.shift(end_time, milliseconds: -(step * 7000))
    {start_ms, end_ms} = {clean_time(start_time, interval), clean_time(end_time, interval)}
    missing = calc_missing(symbol, interval, start_ms, end_ms)

    for start_ms..end_ms <- missing do
      fetch(symbol, interval, start_ms, end_ms)
      |> double_link()
      |> Frame.dominion()
      |> delink()
      |> cache_candles(symbol, interval)
    end
  end

  def cache_candles(frames, symbol, interval) do
    step = Util.to_ms(interval)

    cache =
      cache(symbol, interval)
      |> Enum.reduce(frames, fn g, acc -> acc ++ g.candles end)
      |> Enum.uniq_by(& &1.open_time)
      |> Enum.sort_by(& &1.open_time)
      |> List.Helper.group_adjacent_fn(&(abs(&1.open_time - &2.open_time) >= step))
      |> Enum.map(fn g ->
        %CandleGroup{
          k: Range.new(List.first(g).open_time, List.last(g).open_time),
          candles: g
        }
      end)

    write_cache_to_disk(cache, symbol, interval)
    Cache.set(cache_key(symbol, interval), cache)
  end

  def merge_groups(%{k: f1..l1, candles: c1}, %{k: f2..l2, candles: c2}),
    do: %CandleGroup{
      k: Range.new(min(f1, f2), max(l1, l2)),
      candles: c1 ++ c2
    }

  defp clean_time(time, interval), do: clean(to_ms(time), to_ms(interval))
  defp clean(ms, step), do: ms - rem(ms, step)

  defp fetch(symbol, interval, start_ms, last_ms) when start_ms < last_ms do
    step = to_ms(interval)
    end_ms = min(start_ms + step * 500, last_ms)

    IO.puts("Downloading #{(end_ms - start_ms) / step} candles...")

    url =
      "https://api.binance.com/api/v3/klines?" <>
        "symbol=#{symbol}" <>
        "&interval=#{interval}" <>
        "&startTime=#{:erlang.float_to_binary(start_ms + 0.0, decimals: 0)}" <>
        "&endTime=#{:erlang.float_to_binary(end_ms + 0.0, decimals: 0)}"

    candles =
      HTTPoison.get(url)
      |> case do
        {:ok, response} -> response.body
        {:error, response} -> raise response
      end
      |> Jason.decode!(%{keys: :atoms!})
      |> Enum.map(&Candle.new/1)

    candles ++ fetch(symbol, interval, end_ms, last_ms)
  end

  defp fetch(_, _, _, _), do: []

  defp calc_missing(symbol, interval, start_ms, end_ms) do
    step = to_ms(interval)
    {start_ms, end_ms} = {clean(start_ms, step), clean(end_ms, step)}
    cache = cache(symbol, interval)

    available = Enum.map(cache, & &1.k)

    Range.Helper.subtract(start_ms..end_ms, available)
    |> List.flatten()
    |> Enum.filter(fn a..b -> abs(a - b) >= step end)
  end

  def candles(), do: candles("BTCUSDT", "1h")

  def candles(symbol, interval),
    do: candles(symbol, interval, Timex.beginning_of_day(DateTime.utc_now()))

  def candles(symbol, interval, end_time) do
    step = Util.to_ms(interval)
    candles(symbol, interval, Timex.shift(end_time, milliseconds: -(step * 1000)), end_time)
  end

  def candles(symbol, interval, start_time, end_time) do
    build_cache(symbol, interval)

    step = to_ms(interval)
    {start_ms, end_ms} = {clean(to_ms(start_time), step), clean(to_ms(end_time), step) + step}

    missing = calc_missing(symbol, interval, start_ms, end_ms)

    for start_ms..end_ms <- missing do
      fetch(symbol, interval, start_ms, end_ms)
      |> cache_candles(symbol, interval)
    end

    cache(symbol, interval)
    |> Enum.find(fn %{k: a..b} -> a <= start_ms and b >= end_ms end)
    |> case do
      %{candles: candles} ->
        Enum.slice(
          candles,
          index(List.first(candles).open_time, start_ms, step),
          index(List.first(candles).open_time, end_ms, step)
        )

      _ ->
        []
    end
  end

  def index(start_ms, end_ms, step), do: round((end_ms - start_ms) / step)

  def candles_json(symbol, interval, start_time, end_time) do
    candles(symbol, interval, start_time, end_time)
    |> Jason.encode!()
  end

  def file_path(symbol, interval) do
    unless File.exists?(Path.dirname("cache")), do: File.mkdir_p!(Path.dirname("cache"))

    Path.join("cache", "#{symbol}-#{interval}.json")
  end

  def cache_key(symbol, interval), do: "#{symbol}_#{interval}"
end
