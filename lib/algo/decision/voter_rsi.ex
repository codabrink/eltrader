defmodule Voter.RSI do
  use Configurable,
    config: %{
      influence: %R{
        value: 1
      }
    }

  @behaviour Decision.Behavior
end
