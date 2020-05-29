defmodule C do
  # number of candles considered in cancluating momentum
  defstruct momentum_width: 3,
            # distance from nearest peak needed to be considered a reversal
            reversal_distance: 2,
            reversal_strength_price_delta_factor: 1,
            reversal_strength_distance_factor: 1,
            line_anchor_distance: 30

  def init(config \\ %C{}) do
    if :ets.whereis(:algo_config) === :undefined,
      do: :ets.new(:algo_config, [:named_table, :set, :public])

    config
    |> Map.from_struct()
    |> Enum.each(fn {k, v} ->
      :ets.insert(:algo_config, {k, v})
    end)
  end

  def fetch(key) do
    :ets.lookup(:algo_config, key)
    |> List.first()
    |> case do
      {_, v} -> v
      nil -> nil
    end
  end

  def save(config \\ %C{}) do
    {:ok, file} = File.open(Path.join("cache", "config.json"), [:write])

    json =
      config
      |> Poison.encode!()

    IO.binwrite(file, json)
    File.close(file)
  end

  def read() do
    path = Path.join("cache", "config.json")
    unless File.exists?(path), do: save()

    File.read!(path)
    |> Poison.decode!(as: %C{})
  end
end