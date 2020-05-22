defmodule Reversal do
  @derive {Poison.Encoder, except: [:frame, :candle, :prev_top, :prev_bottom]}
  defstruct [:type, :strength, :prev_top, :prev_bottom, :diff, :frame, :candle, :constrained]

  defmodule Payload do
    defstruct [:frames, :prev_top, :prev_bottom]
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
        prev_bottom: bottom || p.prev_bottom
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
      case type do
        :top ->
          if p.prev_top, do: frame.candle.close - p.prev_top.candle.close, else: 0

        :bottom ->
          if p.prev_top, do: frame.candle.close - p.prev_bottom.candle.close, else: 0
      end

    %Reversal{
      type: type,
      frame: frame,
      candle: frame.candle,
      prev_top: p.prev_top,
      prev_bottom: p.prev_bottom,
      diff: diff,
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
end
