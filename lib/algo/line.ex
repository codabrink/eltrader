defmodule Line do
  @type top_bottom :: :top | :bottom
  defstruct [:point, :frame, :angle]

  @spec new(%Frame{}, top_bottom) :: %Line{}
  def new(frame, type) do
    y =
      case type do
        :top -> frame.high
        :bottom -> frame.low
      end

    %Geo.Point{coordinates: {frame.close_time, y}}

    %Line{
      frame: frame
    }
  end
end
