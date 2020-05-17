defmodule Candle do
  defstruct open_time: nil,
            open: nil,
            close: nil,
            high: nil,
            low: nil,
            close_time: nil,
            volume: 0,
            frame: nil

  def new(rc) do
    %Candle{
      open_time: rc[0],
      open: rc[1],
      high: rc[2],
      low: rc[3],
      close: rc[4],
      volume: rc[5],
      close_time: rc[6]
    }
  end
end
