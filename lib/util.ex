require Protocol

defmodule Util do
  def split_around(list, index) do
    {first, last} = Enum.split(list, index)
    first = Enum.reverse(first)
    [_ | last] = last
    {first, last}
  end
end

Protocol.derive(Jason.Encoder, Geo.Point)
Protocol.derive(Jason.Encoder, Geo.LineString)

defmodule JasonEncoder do
  alias Jason.Encoder

  # defimpl Encoder, for: Geo.Point do
  #   def encode(data, options) do
  #     Geo.JSON.encode!(data)
  #     |> Jason.encode!(options)
  #   end
  # end

  defimpl Encoder, for: Tuple do
    def encode(data, options) when is_tuple(data) do
      data
      |> Tuple.to_list()
      |> Encoder.List.encode(options)
    end
  end
end
