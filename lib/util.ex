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

defmodule Range.Helper do
  def to_list(range, step \\ 1) do
    first..last = range
    _to_list([], first, last, step)
  end

  defp _to_list(acc, num, last, _) when num > last, do: Enum.reverse(acc)

  defp _to_list(acc, num, last, step) do
    _to_list([num | acc], num + step, last, step)
  end

  def diff(range, range) do
  end
end

defmodule List.Helper do
  def subtract(list, []), do: list

  def subtract(list1, [list2 | lists]) do
    subtract(list1 -- list2, lists)
  end

  def group_adjacent_fn([], _), do: []
  def group_adjacent_fn([item | items], func), do: _group_adjacent_fn(items, [[item]], func)

  defp _group_adjacent_fn([], [group | groups], _),
    do: Enum.reverse([Enum.reverse(group) | groups])

  defp _group_adjacent_fn([item | items], [group | groups], func) do
    [last | _] = group

    cond do
      func.(item, last) -> _group_adjacent_fn(items, [[item | group] | groups], func)
      true -> _group_adjacent_fn(items, [[item], Enum.reverse(group) | groups], func)
    end
  end

  def group_adjacent([], _), do: []
  def group_adjacent([item | items], step \\ 1), do: _group_adjacent(items, [[item]], step)
  defp _group_adjacent([], [group | groups], _), do: Enum.reverse([Enum.reverse(group) | groups])

  defp _group_adjacent([item | items], [group | groups], step) do
    [last | _] = group

    cond do
      abs(item - last) <= step -> _group_adjacent(items, [[item | group] | groups], step)
      true -> _group_adjacent(items, [[item], Enum.reverse(group) | groups], step)
    end
  end
end
