defmodule Decider do
  @spec decide(%Frame{}, %Api.Sim.Stake{}) :: %Frame{}
  def decide(frame, stake) do
    bias =
      frame.votes
      |> Enum.reduce(0, fn v, acc -> acc + v.bias end)

    stake =
      cond do
        bias > 0.75 ->
          Api.Sim.buy(stake, frame)

        bias < -0.75 ->
          Api.Sim.sell(stake, frame)

        true ->
          stake
      end

    %{frame | stake: stake}
  end
end
