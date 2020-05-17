defmodule Data do
  def cache_candles(symbol \\ "BTCUSDT", interval \\ "5m") do
    {:ok, file} = File.open(Path.join("cache", "#{symbol}-#{interval}.json"), [:write])

    result =
      HTTPoison.get("https://api.binance.com/api/v3/klines?symbol=#{symbol}&interval=#{interval}")
      |> case do
        {:ok, response} -> response.body
        {:error, _} -> "Binance api request didn't work"
      end
      |> Poison.Parser.parse!(%{keys: :atoms!})
      |> Enum.map(&Candle.new/1)
      |> Poison.encode!()

    IO.binwrite(file, result)
    File.close(file)
  end

  def candle_data(symbol \\ "BTCUSDT", interval \\ "5m") do
    unless File.exists?(file_path(symbol, interval)) do
      cache_candles(symbol, interval)
    end

    File.read!(file_path(symbol, interval))
    |> Poison.decode!(as: [%Candle{}])
  end

  def file_path(symbol, interval) do
    unless File.exists?(Path.dirname("cache")) do
      File.mkdir_p!(Path.dirname("cache"))
    end

    Path.join("cache", "#{symbol}-#{interval}.json")
  end
end
