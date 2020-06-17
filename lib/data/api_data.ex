defmodule ApiData do
  def cache_api(symbol, interval, start_time, end_time) do
    {start_ms, end_ms} = to_ms(start_time, end_time)
    {:ok, file} = File.open(file_path(symbol, interval, start_time, end_time), [:write])

    url =
      "https://api.binance.com/api/v3/klines?" <>
        "symbol=#{symbol}" <>
        "&interval=#{interval}" <>
        "&startTime=#{start_ms}" <>
        "&endTime=#{end_ms}"

    result =
      HTTPoison.get(url)
      |> case do
        {:ok, response} -> response.body
      end

    IO.binwrite(file, result)
    File.close(file)
  end

  def candles(symbol, interval, start_time \\ nil, end_time \\ nil) do
    start_time =
      start_time ||
        DateTime.utc_now()
        |> Timex.shift(days: -10)

    end_time = end_time || DateTime.utc_now()

    unless File.exists?(file_path(symbol, interval, start_time, end_time)),
      do: cache_api(symbol, interval, start_time, end_time)

    File.read!(file_path(symbol, interval, start_time, end_time))
    |> Poison.Parser.parse!(%{keys: :atoms!})
    |> Enum.map(&Candle.new/1)
  end

  def candles_json(symbol, interval, start_time, end_time) do
    candles(symbol, interval, start_time, end_time)
    |> Poison.encode!()
  end

  def file_path(symbol, interval, start_time, end_time) do
    unless File.exists?(Path.dirname("cache")), do: File.mkdir_p!(Path.dirname("cache"))
    {start_ms, end_ms} = to_ms(start_time, end_time)

    Path.join("cache", "#{symbol}-#{interval}-#{start_ms}-#{end_ms}.json")
  end

  def to_ms(s, e), do: {DateTime.to_unix(s, :millisecond), DateTime.to_unix(e, :millisecond)}
end
