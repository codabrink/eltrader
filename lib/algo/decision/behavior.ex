defmodule Decision.Behavior do
  @callback run(%Frame{}) :: [%Vote{}]
end
