defmodule Reversal do
  @derive {Poison.Encoder, except: [:frame, :candle, :prev_top, :prev_bottom]}
  defstruct [:type, :strength, :prev_top, :prev_bottom, :diff, :frame, :candle, :constrained]

  defmodule Payload do
    defstruct [:frames, :prev, :prev_top, :prev_bottom]
  end

  def reversals(frames), do: reversals(frames, %Payload{frames: frames})

  defp reversals([], _), do: []

  defp reversals([frame | tail], p) do
    surrounding = Frame.surrounding(p.frames, frame.index, C.fetch(:reversal_min_distance))
    top = new(:top, surrounding, frame, p)
    bottom = new(:bottom, surrounding, frame, p)

    p = %{
      p
      | prev_top: top || p.prev_top,
        prev_bottom: bottom || p.prev_bottom,
        prev: top || bottom || p.prev
    }

    [
      %Frame{
        frame
        | top_reversal: top,
          bottom_reversal: bottom
      }
      | reversals(tail, p)
    ]
  end

  defp new(type, [], frame, p) do
    diff =
      case {type, p.prev_top, p.prev_bottom} do
        {:top, nil, _} -> 0
        {:bottom, _, nil} -> 0
        {:top, prev_top, _} -> frame.candle.close - prev_top.candle.open
        {:bottom, _, prev_bottom} -> frame.candle.close - prev_bottom.candle.open
      end

    %Reversal{
      type: type,
      frame: frame,
      candle: frame.candle,
      prev_top: p.prev_top,
      prev_bottom: p.prev_bottom,
      diff: diff,
      strength: strength(type, frame, p.prev),
      constrained:
        case type do
          :top ->
            if p.prev_top, do: p.prev_top.candle.high > frame.candle.high, else: 0

          :bottom ->
            if p.prev_bottom, do: p.prev_bottom.candle.low < frame.candle.low, else: 0
        end
    }
  end

  defp new(type, [head | tail], frame, p) do
    cond do
      type === :top && head.candle.high > frame.candle.high -> nil
      type === :bottom && head.candle.low < frame.candle.low -> nil
      true -> new(type, tail, frame, p)
    end
  end

  defp strength(_, _, nil), do: 0

  defp strength(type, frame, prev) do
    price_delta =
      case type do
        :top -> frame.candle.high
        :bottom -> frame.candle.low
      end - prev.candle.open

    price_delta = abs(price_delta) * C.fetch(:reversal_strength_price_delta_factor)
    prev_distance = (frame.index - prev.frame.index) * C.fetch(:reversal_strength_distance_factor)
    price_delta + prev_distance
  end
end
