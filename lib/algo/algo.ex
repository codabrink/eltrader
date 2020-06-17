defmodule Algo do
  defmodule Payload do
    use TypedStruct

    typedstruct do
      field :frames, [%Frame{}]
      field :trend_lines, %TrendLines{}
      field :votes, [%Vote{}]
      field :bias, float()
    end
  end

  def annotate(), do: annotate(ApiData.candles())

  def run(), do: run(ApiData.candles())
  def run(candles), do: candles |> annotate() |> add_votes()

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

  @spec sim() :: [%Payload{}]
  def sim() do
    candles = ApiData.candles()

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
