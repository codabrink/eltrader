defmodule ApiData do
  def cache_api(symbol, interval) do
    {:ok, file} = File.open(Path.join("cache", "#{symbol}-#{interval}.json"), [:write])

    result =
      HTTPoison.get("https://api.binance.com/api/v3/klines?symbol=#{symbol}&interval=#{interval}")
      |> case do
        {:ok, response} -> response.body
      end

    IO.binwrite(file, result)
    File.close(file)
  end

  def candles(symbol \\ "BTCUSDT", interval \\ "5m") do
    unless File.exists?(file_path(symbol, interval)), do: cache_api(symbol, interval)

    File.read!(file_path(symbol, interval))
    |> Poison.Parser.parse!(%{keys: :atoms!})
    |> Enum.map(&Candle.new/1)
  end

  def candles_json(symbol \\ "BTCUSDT", interval \\ "5m") do
    candles(symbol, interval)
    |> Poison.encode!()
  end

  def file_path(symbol, interval) do
    unless File.exists?(Path.dirname("cache")), do: File.mkdir_p!(Path.dirname("cache"))

    Path.join("cache", "#{symbol}-#{interval}.json")
  end
end
