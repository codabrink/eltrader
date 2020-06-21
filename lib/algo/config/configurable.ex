defmodule R do
  defstruct [:range, :value, step: 1, denominator: 1]
end

defmodule Configurable do
  @type module_config :: map()

  @callback config() :: module_config
end
