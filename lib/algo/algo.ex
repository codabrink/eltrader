defmodule Algo do
  @default_symbol "BTCUSDT"
  @default_interval "15m"

  defmodule Payload do
    @derive Jason.Encoder
    use TypedStruct

    typedstruct do
      field :frames, [%Frame{}]
      field :trend_lines, %TrendLines{}
      field :votes, [%Vote{}]
    end
  end

  def run(), do: run(@default_symbol, @default_interval)

  def run(candles), do: candles |> annotate() |> add_votes()
  def run(symbol, interval), do: ApiData.candles(symbol, interval) |> run()

  def annotate(), do: annotate(@default_symbol, @default_interval)
  def annotate(symbol, interval), do: ApiData.candles(symbol, interval) |> annotate()

  def annotate(candles) do
    C.init()

    frames =
      to_frames(candles, 0, nil)
      |> Frame.merge_dominion()
      |> Reversal.merge_reversals()

    %Payload{
      frames: frames,
      trend_lines: TrendLines.new(frames)
    }
  end

  @spec add_votes(%Payload{}) :: %Payload{}
  def add_votes(payload) do
    votes = []
    votes = Decision.TrendReclaim.run(payload) ++ votes

    %{payload | votes: votes}
  end

  def qsim() do
    sim()
    nil
  end

  def votes_for(symbol, interval, frame) do
    sim_width_hours = C.fetch(:sim_width_hours)

    end_time =
      frame.open_time
      |> DateTime.from_unix!(:millisecond)

    start_time = end_time |> Timex.shift(hours: -sim_width_hours)

    candles = ApiData.candles(symbol, interval, start_time, end_time)
  end

  def sim(symbol \\ @default_symbol, interval \\ @default_interval) do
    candles = ApiData.candles(symbol, interval)

    half_len = floor(length(candles) / 2)

    head = Enum.take(candles, half_len)
    tail = Enum.slice(candles, half_len, length(candles) - half_len)

    _sim(head, tail)
  end

  defp _sim([], _), do: []
  defp _sim(_, []), do: []

  defp _sim([_ | head], [candle | tail]) do
    [run(head) | _sim(head ++ [candle], tail)]
  end

  def quiet() do
    annotate()
    nil
  end

  defp to_frames([], _, _), do: []

  defp to_frames([candle | tail], i, prev) do
    frame =
      Frame.new(
        candle,
        prev,
        i
      )

    [frame | to_frames(tail, i + 1, frame)]
  end
end
