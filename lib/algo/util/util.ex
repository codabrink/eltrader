require Protocol

defmodule Util do
  def inspect(o, times) do
  end

  def to_ms([]), do: []
  def to_ms([a | t]), do: [to_ms(a) | to_ms(t)]

  def to_ms(%DateTime{} = interval),
    do: DateTime.to_unix(interval, :millisecond) |> round()

  def to_ms(interval) when is_bitstring(interval),
    do: _to_ms(Regex.run(~r{(\d+)([a-zA-Z])}, interval))

  defp _to_ms([_, n, u]) do
    case [String.to_integer(n), u] do
      [n, "m"] -> Timex.Duration.from_minutes(n)
      [n, "h"] -> Timex.Duration.from_hours(n)
      [n, "d"] -> Timex.Duration.from_days(n)
      [n, "w"] -> Timex.Duration.from_weeks(n)
      _ -> Timex.Duration.from_days(1)
    end
    |> Timex.Duration.to_milliseconds()
    |> round()
  end

  defp _to_ms(_), do: nil

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

  defp _to_list(acc, num, last, _) when num >= last, do: Enum.reverse([last | acc])

  defp _to_list(acc, num, last, step) do
    _to_list([num | acc], num + step, last, step)
  end

  def subtract(a, []), do: [a]
  def subtract(a, [b]), do: subtract(a, b)
  def subtract(a, [b | tail]), do: subtract(subtract(a, b), subtract(a, tail))

  def subtract(a..b, c..d) do
    cond do
      a in c..d and b in c..d -> []
      c in a..b and d in a..b -> [a..c, b..d]
      a in c..d -> [d..b]
      b in c..d -> [a..c]
      true -> a..b
    end
  end

  def adjacent?(a..b, c..d, step) do
    c in a..b || d in a..b ||
      abs(d - a) <= step || abs(c - b) <= step ||
      abs(c - a) <= step || abs(d - b) <= step
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
  def group_adjacent([item | items], step), do: _group_adjacent(items, [[item]], step || 1)
  defp _group_adjacent([], [group | groups], _), do: Enum.reverse([Enum.reverse(group) | groups])

  defp _group_adjacent([item | items], [group | groups], step) do
    [last | _] = group

    cond do
      abs(item - last) <= step -> _group_adjacent(items, [[item | group] | groups], step)
      true -> _group_adjacent(items, [[item], Enum.reverse(group) | groups], step)
    end
  end
end
