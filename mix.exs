defmodule Trader.MixProject do
  use Mix.Project

  def project do
    [
      app: :trader,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :plug_cowboy]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug_cowboy, "~> 2.3.0"},
      {:jason, " ~> 1.2.1"},
      {:httpoison, "~> 1.6.2"},
      {:timex, "~> 3.6.2"},
      {:typed_struct, "~> 0.2.0"},
      # {:topo, "0.4.0"},
      {:topo, git: "https://github.com/codabrink/topo.git"}
      # {:dep_from_hexpm, "~> 0.3.0"},
    ]
  end
end
