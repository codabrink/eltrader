defmodule Decision.TrendBreak do
  @moduledoc """
  When a trend is broken and breaks down, it's bearish.
  This module influences the bias negatively when this is recognized.
  """
  defstruct [:start_frame, :end_frame, :width, :depth]

  @behaviour Decision.Behavior
  @behaviour Configurable
  alias Trader.Cache

  @config %{
    influence: %R{
      range: 0..1,
      value: 1,
      step: 0.1
    },
    max_distance: %R{
      range: 0..5,
      value: 0.01,
      denominator: 100
    }
  }

  @impl Configurable
  def config(), do: __MODULE__ |> to_string |> Cache.config() || @config

  def config(key) do
    %{^key => %{:value => value}} = config()
    value
  end

  @impl Decision.Behavior
  @spec run(%Frame{}) :: [%Vote{}]
  def run(%Frame{} = frame) do
    lines = frame.trend_lines.top_lines ++ frame.trend_lines.bottom_lines
    votes(lines, Enum.reverse(frame.frames), [])
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
    bounce_count = count_bounces(Enum.reverse(line.crosses))
    max_distance = config(:max_distance)

    cond do
      abs(distance) < max_distance * frame.close ->
        votes(lines, r_frames, [vote(line, bounce_count) | votes])

      true ->
        votes(lines, r_frames, votes)
    end
  end

  def vote(_, bounce_count) when bounce_count > 2,
    do: %Vote{source: Decision.TrendReclaim, bias: -1}

  def vote(_, _), do: %Vote{source: Decision.TrendReclaim, bias: 0}

  @spec count_bounces([%Line.Cross{}]) :: number
  ## should doing percentage of bounces over time
  def count_bounces([]), do: 0
  def count_bounces([cross | tail]), do: count_bounces(cross.type, tail, 0)

  def count_bounces(:bounce, [cross | tail], count),
    do: count_bounces(cross.type, tail, count + 1)

  def count_bounces(_, _, count), do: count
end
