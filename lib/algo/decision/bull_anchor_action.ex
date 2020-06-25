defmodule Decision.BullAnchorAction do
  @behaviour Decision.Behavior
  use Configurable,
    config: %{
      influence: %R{
        range: 0..1,
        value: 1,
        step: 0.1
      }
    }

  @impl Decision.Behavior
  def run(%Frame{} = frame) do
  end
end
