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

  def cache_candles(candles, symbol, interval) do
    range = Range.new(List.first(candles).open_time, List.last(candles).open_time)

    cache =
      [%CandleGroup{k: range, candles: candles} | cache(symbol, interval)]
      |> compile()

    write_cache_to_disk(cache, symbol, interval)
    Trader.Cache.set(cache_key(symbol, interval), cache)
  end

  def compile([u | unbuilt]), do: compile(unbuilt, [u])
  def compile([], built), do: built

  def compile([u | unbuilt], built) do
    compile(unbuilt, _compile(u, built))
  end

  defp _compile(u, []), do: [u]

  defp _compile(u, [b | built]) do
    cond do
      Range.disjoint?(u.k, b.k) -> [b | _compile(u, built)]
      true -> _compile(merge_groups(u, b), built)
    end
  end

  def merge_groups(%{k: f1..l1, candles: c1}, %{k: f2..l2, candles: c2}),
    do: %CandleGroup{
      k: Range.new(min(f1, f2), max(l1, l2)),
      candles: (c1 ++ c2) |> Enum.uniq_by(& &1.open_time) |> Enum.sort_by(& &1.open_time)
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
    do: candles(symbol, interval, Timex.shift(end_time, days: -14), end_time)

  def candles(symbol, interval, start_time, end_time) do
    cache = cache(symbol, interval)
    [start_ms, end_ms] = Util.to_ms([start_time, end_time])
    step = Util.to_ms(interval)

    desired_open_times = Range.Helper.to_list(start_ms..end_ms, step)
    available_open_times = Enum.map(cache, &Range.Helper.to_list(&1.k, step))

    missing =
      List.Helper.subtract(desired_open_times, available_open_times)
      |> List.Helper.group_adjacent(step)

    for group <- missing do
      start_ms = List.first(group)
      end_ms = List.last(group)

      download_candles(symbol, interval, start_ms, end_ms)
      |> cache_candles(symbol, interval)
    end

    cache = cache(symbol, interval)

    group =
      Enum.find(cache, fn g ->
        first..last = g.k
        first <= start_ms && last >= end_ms
      end)

    Enum.slice(
      group.candles,
      index(List.first(group.candles).open_time, start_ms, step),
      index(start_ms, end_ms, step)
    )
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
