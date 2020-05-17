defmodule Utils do
  def defaults(defaults, options) do
    options = Keywords.merge(defaults, options) |> Enum.into(%{})
  end
end
