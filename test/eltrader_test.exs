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
  end

  test "Utils work" do
    assert Util.between?(100.5, 90.1, 110.4)
  end

  test "Double link is working" do
    %{frames: frames} = Algo.annotate()
    [frame | frames] = frames

    assert frame.index === 0
    assert frame.next.index === 1
    assert frame.next.next.index === 2
  end
end
