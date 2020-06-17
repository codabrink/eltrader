defmodule Reversal do
  @derive {Jason.Encoder, except: [:frame, :candle, :prev_top, :prev_bottom]}
  @type rev_type :: :top | :bottom
  defstruct [
    :type,
    :strength,
    :prev_top,
    :prev_bottom,
    :diff,
    :frame,
    :constrained
  ]

  defmodule Payload do
    defstruct [:frames, :prev, :prev_top, :prev_bottom]
  end

  def merge_reversals(frames), do: merge_reversals(frames, %Payload{frames: frames})
  defp merge_reversals([], _), do: []

  defp merge_reversals([frame | tail], p) do
    surrounding = Frame.surrounding(p.frames, frame.index, C.fetch(:reversal_distance))
    top = new(:top, surrounding, frame, p)
    bottom = new(:bottom, surrounding, frame, p)

    p = %{
      p
      | prev_top: top || p.prev_top,
        prev_bottom: bottom || p.prev_bottom,
        prev: top || bottom || p.prev
    }

    [
      %{frame | top_reversal: top, bottom_reversal: bottom}
      | merge_reversals(tail, p)
    ]
  end

  defp new(type, [], frame, p) do
    diff =
      case {type, p.prev_top, p.prev_bottom} do
        {:top, nil, _} -> 0
        {:bottom, _, nil} -> 0
        {:top, prev_top, _} -> frame.close - prev_top.frame.open
        {:bottom, _, prev_bottom} -> frame.close - prev_bottom.frame.open
      end

    %Reversal{
      type: type,
      frame: frame,
      prev_top: p.prev_top,
      prev_bottom: p.prev_bottom,
      diff: diff,
      strength: strength(type, frame, p.prev),
      constrained:
        case {type, p} do
          {:top, %{prev_top: %{frame: %{high: high}}}} -> high < frame.high
          {:bottom, %{prev_bottom: %{frame: %{low: low}}}} -> low > frame.low
          _ -> false
        end
    }
  end

  defp new(type, [head | tail], frame, p) do
    cond do
      type === :top && head.high > frame.high -> nil
      type === :bottom && head.low < frame.low -> nil
      true -> new(type, tail, frame, p)
    end
  end

  defp strength(_, _, nil), do: 0

  defp strength(type, %Frame{} = frame, prev) do
    price_delta =
      case type do
        :top -> frame.high
        :bottom -> frame.low
      end - prev.frame.open

    price_delta = abs(price_delta) * C.fetch(:reversal_strength_price_delta_factor)
    prev_distance = (frame.index - prev.frame.index) * C.fetch(:reversal_strength_distance_factor)
    price_delta + prev_distance
  end
end
