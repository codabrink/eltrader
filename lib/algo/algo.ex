defmodule Algo do
  defmodule Payload do
    defstruct [:frames, :trend_lines, :votes, :bias]
  end

  def annotate(), do: annotate(ApiData.candles())

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

  @spec sim() :: [%Payload{}]
  def sim() do
    reverse_candles = ApiData.candles() |> Enum.reverse()
    _sim(reverse_candles)

    nil
  end

  defp _sim([]), do: []

  defp _sim([_ | tail]) do
    [run(Enum.reverse(tail)) | _sim(tail)]
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
