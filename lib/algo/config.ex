defmodule Algo.Config do
  defstruct momentum_width: 3,
            reversal_distance: 5

  def save(config \\ %Algo.Config{}) do
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
    |> Poison.decode!(as: %Algo.Config{})
  end
end
