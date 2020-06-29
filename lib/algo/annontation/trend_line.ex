defmodule TrendLine do
  def generate(%Frame{} = frame) do
    {all, _, _} = frame.strong_points
    generate(all, frame)
  end

  def generate([], _), do: []

  def generate([sp | strong_points], frame),
    do: [create(sp, frame) | generate(strong_points, frame)]

  def create(%Point{points_after: [p | _]} = sp, frame) do
    Line.new(frame, sp, p)
  end
end
