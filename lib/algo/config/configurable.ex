defmodule R do
  defstruct [:range, :value]
end

defmodule Configurable do
  @type module_config :: map()

  @callback config() :: module_config
end
