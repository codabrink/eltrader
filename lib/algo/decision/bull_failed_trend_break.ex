defmodule Decision.TrendReclaim do
  @behaviour Decision.Behavior

  @moduledoc """
  When a trend is broken and reclaimed, it's bullish.
  This module influences the bias positively when this is recognized.
  """
  defstruct [:start_frame, :end_frame, :width, :depth]

  @impl Decision.Behavior
  @spec run(%Algo.Payload{}) :: [%Vote{}]
  def run(%Algo.Payload{} = a) do
    bias(a.trend_lines.bottom_lines) ++ bias(a.trend_lines.top_lines)
  end

  @spec run_sum(%Algo.Payload{}) :: float
  def run_sum(a), do: run(a) |> Enum.reduce(0, fn v, acc -> acc + v.bias end)

  @doc """
  Call with each line on the last frame.
  Will only return a trend-reclaim if a complete reclaim is recognized.
  """
  @spec bias([%Line{}]) :: [%Vote{}]
  def bias([]), do: []

  def bias([line | tail]) do
    crosses = Enum.reverse(line.crosses)
    rejection_count = count_rejections(crosses)

    cond do
      rejection_count > 2 -> IO.puts("UP #{rejection_count}")
      true -> nil
    end

    [%Vote{source: Decision.TrendReclaim, bias: 1} | bias(tail)]
  end

  @spec count_rejections([%Line.Cross{}]) :: number
  ## should doing percentage of rejections over time
  def count_rejections([]), do: 0
  def count_rejections([cross | tail]), do: count_rejections(cross.type, tail, 0)

  def count_rejections(:reject, [cross | tail], count),
    do: count_rejections(cross.type, tail, count + 1)

  def count_rejections(_, _, count), do: count
end
