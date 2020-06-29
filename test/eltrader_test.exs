defmodule CandlesTest do
  use ExUnit.Case
  doctest Candles

  test "Converts ranges to lists properly" do
    c =
      Candles.candles(
        "BTCUSDT",
        "15m",
        DateTime.utc_now() |> Timex.shift(days: -1),
        DateTime.utc_now()
      )

    assert length(c) > 1
  end

  test "Data is alright on the last frame" do
    last_frame = Algo.run().frames |> List.last()

    {all, bottom, top} = last_frame.points
    assert length(all) > 1
    assert length(bottom) > 1
    assert length(top) > 1

    {all, bottom, top} = last_frame.strong_points
    assert length(all) > 1
    assert length(bottom) > 1
    assert length(top) > 1

    [sp | _] = all
    assert length(sp.points_after) > 1
    IO.inspect(last_frame.trend_lines)
  end
end
