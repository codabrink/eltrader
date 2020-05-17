defmodule TraderTest do
  use ExUnit.Case
  doctest Trader

  test "greets the world" do
    assert Trader.hello() == :world
  end
end
