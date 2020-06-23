defmodule Candles do
  defmodule CandleGroup do
    use TypedStruct

    typedstruct do
      field :k, Range
      field :candles, [%Candle{}]
    end
  end

  def cache(symbol, interval) do
    read_cache_from_disk(symbol, interval)
    Trader.Cache.get(cache_key(symbol, interval)) || []
  end

  def read_cache_from_disk(symbol, interval) do
    unless Trader.Cache.has_key?(cache_key(symbol, interval)),
      do: _read_cache_from_disk(symbol, interval)
  end

  defp _read_cache_from_disk(symbol, interval) do
    read_candles_from_disk(symbol, interval)
    |> Enum.map(fn group ->
      %CandleGroup{
        k: Range.new(List.first(group).open_time, List.last(group).open_time),
        candles: group
      }
    end)
    |> (&Trader.Cache.set(cache_key(symbol, interval), &1)).()
  end

  def write_cache_to_disk(cache, symbol, interval),
    do: Enum.map(cache, & &1.candles) |> write_candles_to_disk(symbol, interval)

  def write_candles_to_disk(candles, symbol, interval) do
    {:ok, file} = File.open(file_path(symbol, interval), [:write])
    candles |> Jason.encode!() |> (&IO.binwrite(file, &1)).()
    File.close(file)
  end

  def read_candles_from_disk(symbol, interval) do
    File.read(file_path(symbol, interval))
    |> (fn
          {:ok, file} ->
            file
            |> Jason.decode!(%{keys: :atoms!})
            |> Enum.map(fn g -> Enum.map(g, &Candle.new/1) end)

          _ ->
            []
        end).()
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
    Trader.Cache.set(cache_key(symbol, interval), cache)
  end

  def compile([u | unbuilt], step), do: compile(unbuilt, [u], step)
  def compile([], built, _), do: built

  def compile([u | unbuilt], built, step) do
    compile(unbuilt, _compile(u, built, step), step)
  end

  defp _compile(u, [], _), do: [u]

  defp _compile(u, [b | built], step) do
    cond do
      Range.Helper.adjacent?(u.k, b.k, step) -> [b | _compile(u, built, step)]
      true -> _compile(merge_groups(u, b), built, step)
    end
  end

  def merge_groups(%{k: f1..l1, candles: c1}, %{k: f2..l2, candles: c2}),
    do: %CandleGroup{
      k: Range.new(min(f1, f2), max(l1, l2)),
      candles: c1 ++ c2
    }

  @spec download_candles(String.t(), String.t(), number(), number()) :: [%Frame{}]
  def download_candles(symbol, interval, start_ms, end_ms) do
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
        {:error, response} -> IO.puts(response)
      end
      |> Jason.decode!(%{keys: :atoms!})
      |> Enum.map(&Candle.new/1)

    last_candle = List.last(candles)
    all? = last_candle.close_time >= end_ms

    cond do
      all? -> candles
      true -> candles ++ download_candles(symbol, interval, last_candle.open_time, end_ms)
    end
  end

  def candles(), do: candles("BTCUSDT", "15m")

  def candles(symbol, interval),
    do: candles(symbol, interval, Timex.beginning_of_day(DateTime.utc_now()))

  def candles(symbol, interval, end_time),
    do: candles(symbol, interval, Timex.shift(end_time, days: -5), end_time)

  @spec candles(String.t(), String.t(), any, any) :: [%Frame{}]
  def candles(symbol, interval, start_time, end_time) do
    cache = cache(symbol, interval)
    [start_ms, end_ms] = Util.to_ms([start_time, end_time])
    step = Util.to_ms(interval)

    available = Enum.map(cache, & &1.k)

    missing =
      Range.Helper.subtract(start_ms..end_ms, available)
      |> List.flatten()
      |> Enum.filter(fn a..b -> abs(a - b) >= step end)

    for range <- missing do
      start_ms..end_ms = range

      download_candles(symbol, interval, start_ms, end_ms)
      |> cache_candles(symbol, interval)
    end

    cache(symbol, interval)
    |> Enum.find(fn g ->
      Range.Helper.adjacent?(start_ms..end_ms, g.k, step)
    end)
    |> case do
      %{candles: candles} ->
        Enum.slice(
          candles,
          index(List.first(candles).open_time, start_ms, step),
          index(start_ms, end_ms, step)
        )

      _ ->
        []
    end
  end

  def index(start_ms, end_ms, step), do: floor((end_ms - start_ms) / step)

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
