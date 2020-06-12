defmodule Decision.Behavior do
  @callback run(%Algo.Payload{}) :: [%Vote{}]
end
