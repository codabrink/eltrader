defmodule Candle do
  defstruct [
    :open_time,
    :open,
    :high,
    :low,
    :close,
    :volume,
    :close_time,
    :num_trades,
    :asset_volume,
    :body_geom,
    :stem_geom
  ]

  def new(rc) do
    open_time = Enum.at(rc, 0)
    open = String.to_float(Enum.at(rc, 1))
    high = String.to_float(Enum.at(rc, 2))
    low = String.to_float(Enum.at(rc, 3))
    close = String.to_float(Enum.at(rc, 4))

    # Consider making geom a square
    body_geom = %Geo.LineString{coordinates: [{open_time, open}, {open_time, close}]}
    stem_geom = %Geo.LineString{coordinates: [{open_time, high}, {open_time, low}]}

    %Frame{
      open_time: open_time,
      open: open,
      high: high,
      low: low,
      close: close,
      volume: String.to_float(Enum.at(rc, 5)),
      close_time: Enum.at(rc, 6),
      asset_volume: String.to_float(Enum.at(rc, 7)),
      num_trades: Enum.at(rc, 8),
      body_geom: body_geom,
      stem_geom: stem_geom
    }
  end
end
