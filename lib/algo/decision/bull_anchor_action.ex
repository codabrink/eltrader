defmodule Decision.BullAnchorAction do
  @behaviour Decision.Behavior
  @behaviour Configurable
  alias Trader.Cache

  @config %{
    influence: %R{
      range: 0..1,
      value: 1,
      step: 0.1
    }
  }

  @impl Configurable
  def config(), do: __MODULE__ |> to_string |> Cache.config() || @config

  def config(key) do
    %{^key => %{:value => value}} = config()
    value
  end

  @impl Decision.Behavior
  def run(%Frame{} = frame) do
  end
end
