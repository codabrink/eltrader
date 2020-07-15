defmodule TestUtil do
  def enable(), do: Cache.set(:testing, true)
  def disable(), do: Cache.set(:testing, false)

  def is_sorted(list, f, order \\ :asc) do
    if Cache.testing?(), do: _is_sorted(list, f, order)
  end

  defp _is_sorted([a, b | rest], f, order) do
    _is_sorted({f.(a), f.(b)}, order)
    _is_sorted([b | rest], f, order)
  end

  defp _is_sorted(_, _, _), do: true
  defp _is_sorted({a, b}, :asc) when a > b, do: raise("Not sorted. #{a} #{b}")
  defp _is_sorted({a, b}, :desc) when a < b, do: raise("Not sorted. #{a} #{b}")
  defp _is_sorted(_, _), do: true
end
