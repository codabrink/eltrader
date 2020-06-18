defmodule CandlesTest do
  use ExUnit.Case
  doctest Candles

  test "Converts ranges to lists properly" do
    assert Range.Helper.to_list(0..100, 10) == [0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100]

    assert List.Helper.group_adjacent([1, 2, 3, 6, 7, 8, 9, 20, 22]) == [
             [1, 2, 3],
             [6, 7, 8, 9],
             [20],
             [22]
           ]

    assert List.Helper.subtract([1, 2, 3, 4, 5, 6, 7], [[3], [7]]) == [1, 2, 4, 5, 6]
  end
end
