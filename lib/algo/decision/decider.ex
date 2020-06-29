defmodule Decider do
  @spec decide(%Frame{}, %Api.Sim.Stake{}) :: %Frame{}
  def decide(frame, stake) do
    bias =
      frame.votes
      |> Enum.reduce(0, fn v, acc -> acc + v.bias end)

    stake =
      cond do
        bias > 0.75 ->
          IO.puts("BUY @#{frame.open}, bias: #{bias}")
          Api.Sim.buy(stake, frame)

        bias < -0.75 ->
          IO.puts("SELL @#{frame.open}, bias: #{bias}")
          Api.Sim.sell(stake, frame)

        true ->
          stake
      end

    %{frame | stake: stake}
  end
end
