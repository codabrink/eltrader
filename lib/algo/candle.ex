defmodule Candle do
  defstruct [:open_time, :open, :high, :low, :close, :volume, :close_time, :num_trades]

  def new(rc) do
    %Candle{
      open_time: Enum.at(rc, 0),
      open: String.to_float(Enum.at(rc, 1)),
      high: String.to_float(Enum.at(rc, 2)),
      low: String.to_float(Enum.at(rc, 3)),
      close: String.to_float(Enum.at(rc, 4)),
      volume: String.to_float(Enum.at(rc, 5)),
      close_time: Enum.at(rc, 6),
      volume: String.to_float(Enum.at(rc, 7)),
      num_trades: Enum.at(rc, 8)
    }
  end
end
