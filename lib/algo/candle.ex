defmodule Candle do
  def new(rc) when is_map(rc), do: struct(Frame, rc)

  def new(rc) do
    open = String.to_float(Enum.at(rc, 1))
    high = String.to_float(Enum.at(rc, 2))
    low = String.to_float(Enum.at(rc, 3))
    close = String.to_float(Enum.at(rc, 4))

    # Consider making geom a square

    %Frame{
      open_time: Enum.at(rc, 0),
      open: open,
      high: high,
      low: low,
      close: close,
      volume: String.to_float(Enum.at(rc, 5)),
      close_time: Enum.at(rc, 6),
      asset_volume: String.to_float(Enum.at(rc, 7)),
      num_trades: Enum.at(rc, 8)
    }
  end
end
