defmodule Frame.Lines do
  defstruct top_anchors: [], bottom_anchors: [], top_lines: [], bottom_lines: []

  defmodule Payload do
    defstruct [:frames]
  end

  defp create_lines([_], _), do: []

  defp create_lines([a, b | tail], type) do
    [Line.new(a, b, type) | create_lines([b | tail], type)]
  end

  @spec new([%Frame{}]) :: %Frame.Lines{}
  def new(frames) do
    anchor_count = floor(C.fetch(:reversal_anchor_pct) / 100 * length(frames))

    bottom_anchors =
      frames
      |> Enum.sort(fn f1, f2 -> f1.bottom_dominion >= f2.bottom_dominion end)
      |> Enum.slice(0..anchor_count)
      |> Enum.sort(fn f1, f2 -> f1.close_time >= f2.close_time end)

    top_anchors =
      frames
      |> Enum.sort(fn f1, f2 -> f1.top_dominion >= f2.top_dominion end)
      |> Enum.slice(0..anchor_count)
      |> Enum.sort(fn f1, f2 -> f1.close_time >= f2.close_time end)

    %Frame.Lines{
      top_anchors: top_anchors,
      bottom_anchors: bottom_anchors,
      top_lines: create_lines(top_anchors, :top),
      bottom_lines: create_lines(bottom_anchors, :bottom)
    }
  end
end
