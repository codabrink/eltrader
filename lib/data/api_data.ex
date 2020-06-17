defmodule ApiData do
  def cache_api(symbol, interval) do
    {:ok, file} = File.open(Path.join("cache", "#{symbol}-#{interval}.json"), [:write])

    start_time =
      DateTime.utc_now()
      |> Timex.shift(days: -10)
      |> DateTime.to_unix(:millisecond)

    end_time = DateTime.utc_now() |> DateTime.to_unix(:millisecond)

    url =
      "https://api.binance.com/api/v3/klines?symbol=#{symbol}&interval=#{interval}&startTime=#{
        start_time
      }&endTime=#{end_time}"

    IO.puts(url)

    result =
      HTTPoison.get(url)
      |> case do
        {:ok, response} -> response.body
      end

    IO.binwrite(file, result)
    File.close(file)
  end

  def candles(symbol \\ "BTCUSDT", interval \\ "15m") do
    unless File.exists?(file_path(symbol, interval)), do: cache_api(symbol, interval)

    File.read!(file_path(symbol, interval))
    |> Poison.Parser.parse!(%{keys: :atoms!})
    |> Enum.map(&Candle.new/1)
  end

  def candles_json(symbol \\ "BTCUSDT", interval \\ "15m") do
    candles(symbol, interval)
    |> Poison.encode!()
  end

  def file_path(symbol, interval) do
    unless File.exists?(Path.dirname("cache")), do: File.mkdir_p!(Path.dirname("cache"))

    Path.join("cache", "#{symbol}-#{interval}.json")
  end
end
