defmodule Utils do
end

defmodule PointEncoder do
  alias Poison.Encoder

  defimpl Encoder, for: Geo.Point do
    def encode(data, options) do
      Geo.JSON.encode!(data)
      |> Poison.encode!(options)
    end
  end
end
