defmodule ApiData do
  def cache_candles(symbol \\ "BTCUSDT", interval \\ "5m") do
    {:ok, file} = File.open(Path.join("cache", "#{symbol}-#{interval}.json"), [:write])

    result =
      HTTPoison.get("https://api.binance.com/api/v3/klines?symbol=#{symbol}&interval=#{interval}")
      |> case do
        {:ok, response} -> response.body
        {:error, err} -> IO.inspect(err)
      end
      |> Poison.Parser.parse!(%{keys: :atoms!})
      |> Enum.map(&Candle.new/1)
      |> Poison.encode!()

    IO.binwrite(file, result)
    File.close(file)
  end

  def candles_json(symbol \\ "BTCUSDT", interval \\ "5m") do
    unless File.exists?(file_path(symbol, interval)), do: cache_candles(symbol, interval)

    File.read!(file_path(symbol, interval))
  end

  def candles(symbol \\ "BTCUSDT", interval \\ "5m") do
    candles_json(symbol, interval)
    |> Poison.decode!(as: [%Candle{}])
  end

  def file_path(symbol, interval) do
    unless File.exists?(Path.dirname("cache")), do: File.mkdir_p!(Path.dirname("cache"))

    Path.join("cache", "#{symbol}-#{interval}.json")
  end
end
