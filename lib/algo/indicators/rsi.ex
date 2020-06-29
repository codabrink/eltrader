defmodule Indicators.RSI do
  def calculate(%{index: index}, width) when index < width, do: nil

  def calculate(frame, width) do
    {avg_gain, avg_loss} =
      frame.before
      |> Enum.take(-width)
      |> gain_loss({0, 0}, width)

    rs = avg_gain / avg_loss
    100 - 100 / (1 + rs)
  end

  defp gain_loss([], {gain, loss}, width), do: {gain / width, loss / width}

  defp gain_loss([frame | frames], {gain, loss}, width),
    do:
      gain_loss(
        frames,
        case frame.close - frame.open do
          diff when diff > 0 -> {gain + diff, loss}
          diff when diff < 0 -> {gain, loss + abs(diff)}
          _ -> {gain, loss}
        end,
        width
      )
end
