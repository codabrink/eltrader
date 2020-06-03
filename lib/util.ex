defmodule Util do
  def split_around(list, index) do
    {first, last} = Enum.split(list, index)
    first = Enum.reverse(first)
    [_ | last] = last
    {first, last}
  end
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
