defmodule Decision.TrendReclaim do
  @behaviour Decision.Behavior

  # percentage of price. If candle is further than this, ignore for line.
  @max_distance 0.01

  @moduledoc """
  When a trend is broken and reclaimed, it's bullish.
  This module influences the bias positively when this is recognized.
  """
  defstruct [:start_frame, :end_frame, :width, :depth]

  @impl Decision.Behavior
  @spec run(%Algo.Payload{}) :: [%Vote{}]
  def run(%Algo.Payload{} = a) do
    lines = a.trend_lines.top_lines ++ a.trend_lines.bottom_lines
    votes(lines, Enum.reverse(a.frames), [])
  end

  @doc """
  Call with each line on the last frame.
  Will only return a trend-reclaim if a complete reclaim is recognized.
  """
  @spec votes([%Line{}], [%Frame{}], [%Vote{}]) :: [%Vote{}]
  def votes([], _, votes), do: votes

  def votes([line | lines], r_frames, votes) do
    [frame | _] = r_frames
    distance = frame.close - Line.y_at(line, frame.index)

    cond do
      abs(distance) < @max_distance * frame.close ->
        vote = vote(line, r_frames)
        votes(lines, r_frames, [vote | votes])

      true ->
        votes(lines, r_frames, votes)
    end
  end

  def vote(line, _) do
    rejection_count = count_rejections(Enum.reverse(line.crosses))

    cond do
      rejection_count > 2 -> %Vote{source: Decision.TrendReclaim, bias: 1}
      true -> %Vote{source: Decision.TrendReclaim, bias: 0}
    end
  end

  @spec count_rejections([%Line.Cross{}]) :: number
  ## should doing percentage of rejections over time
  def count_rejections([]), do: 0
  def count_rejections([cross | tail]), do: count_rejections(cross.type, tail, 0)

  def count_rejections(:reject, [cross | tail], count),
    do: count_rejections(cross.type, tail, count + 1)

  def count_rejections(_, _, count), do: count
end
