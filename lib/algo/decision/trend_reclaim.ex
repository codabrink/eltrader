defmodule Decision.TrendReclaim do
  @moduledoc """
  When a trend is broken and reclaimed, it's bullish.
  This module influences the bias positively when this is recognized.
  """
  defstruct [:start_frame, :end_frame, :width, :depth]

  @doc """
  Call with each line on the last frame.
  Will only return a trend-reclaim if a complete reclaim is recognized.
  """
  def new(line, frame) do
  end
end
