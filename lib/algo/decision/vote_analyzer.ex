defmodule Vote.Result do
  defstruct [:vote, :did_succeed]

  # @spec new(%Vote{}, %Algo.Annotation{}) :: %Vote.Result{}
  def new(vote, %{frames: frames}) do
    diff = Enum.at(frames, vote.frame.index + 5) - vote.frame.close

    %Vote.Result{
      vote: vote,
      did_succeed: did_succeed(diff, vote)
    }
  end

  def did_succeed(diff, vote) do
    cond do
      diff > 0 && vote.bias > 0 -> true
      diff < 0 && vote.bias < 0 -> true
      true -> false
    end
  end
end
