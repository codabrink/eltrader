defmodule Api.Sim do
  @behaviour Configurable
  alias Trader.Cache

  defmodule Stake do
    defstruct [:fiat, :asset]
  end

  @config %{
    slippage: %R{
      range: 1..4,
      denominator: 100,
      value: 0.01
    },
    fee: %R{
      value: 0.00075
    }
  }

  @impl Configurable
  def config(), do: __MODULE__ |> to_string |> Cache.config() || @config

  def config(key) do
    %{^key => %{:value => value}} = config()
    value
  end

  @spec buy(%Stake{}, %Frame{}) :: %Stake{}
  def buy(s, frame) do
    slippage = config(:slippage) + 1
    fee = 1 - config(:fee)

    asset = s.asset + s.fiat / (frame.close * slippage) * fee

    %{s | fiat: 0, asset: asset}
  end

  @spec sell(%Stake{}, %Frame{}) :: %Stake{}
  def sell(p, frame) do
    slippage = 1 - config(:slippage)
    fee = 1 - config(:fee)

    fiat = p.fiat + p.asset * (frame.close * slippage) * fee

    %{p | fiat: fiat, asset: 0}
  end

  def value(p, frame) do
    p.fiat + p.asset * frame.close
  end

  def new(fiat) do
    %Stake{
      fiat: fiat,
      asset: 0
    }
  end
end
