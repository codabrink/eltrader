defmodule R do
  defstruct [:range, :value, step: 1, denominator: 1]
end

defmodule Configurable do
  @type module_config :: map()
  alias Trader.Cache

  defmacro __using__(opts) do
    config = Keyword.get(opts, :config, %{})

    quote do
      def config(), do: __MODULE__ |> to_string |> Cache.config() || unquote(config)

      def config(key) do
        %{^key => %{:value => value}} = config()
        value
      end
    end
  end
end
