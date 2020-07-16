defmodule TestUtil do
  def enable(), do: Cache.set(:testing, true)
  def disable(), do: Cache.set(:testing, false)

  def is_sorted(list, f, order \\ :asc),
    do: if(Cache.testing?(), do: _is_sorted(Enum.map(list, f), order))

  defp _is_sorted([a, b | _], :asc) when a > b, do: raise("Not sorted: #{a} > #{b}")
  defp _is_sorted([a, b | _], :desc) when a < b, do: raise("Not sorted: #{a} < #{b}")
  defp _is_sorted([_ | rest], order), do: _is_sorted(rest, order)
  defp _is_sorted(_, _), do: true
end
