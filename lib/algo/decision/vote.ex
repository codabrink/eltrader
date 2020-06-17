defmodule Vote do
  @derive Jason.Encoder
  defstruct [:source, :frame, :bias]
end
