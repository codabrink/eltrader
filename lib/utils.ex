defmodule Utils do
  def defaults(defaults, options) do
    options = Keywords.merge(defaults, options) |> Enum.into(%{})
  end
end

defmodule TupleEncoder do
  alias Poison.Encoder

  defimpl Encoder, for: Tuple do
    def encode(data, options) when is_tuple(data) do
      data
      |> Tuple.to_list()
      |> Encoder.List.encode(options)
    end
  end
end
