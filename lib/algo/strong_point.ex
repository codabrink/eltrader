defmodule StrongPoint do
  @derive {Jason.Encoder, except: [:frame, :prev, :prev_top, :prev_bottom]}
  defstruct [:frame, :prev, :prev_bottom, :prev_top, :strength, :point]
  @behaviour Configurable
  alias Trader.Cache

  @config %{
    population: %R{
      range: 2..10,
      value: 4
    }
  }

  @impl Configurable
  def config(), do: __MODULE__ |> to_string |> Cache.config() || @config

  def config(key) do
    %{^key => %{:value => value}} = config()
    value
  end

  def generate(frames) do
    population = floor(config(:population) / 100 * length(frames))

    bottom_points =
      frames
      |> Enum.sort(fn f1, f2 -> f1.bottom_dominion >= f2.bottom_dominion end)
      |> Enum.slice(0..population)
      |> Enum.map(fn f -> {:bottom, f} end)

    top_points =
      frames
      |> Enum.sort(fn f1, f2 -> f1.top_dominion >= f2.top_dominion end)
      |> Enum.slice(0..population)
      |> Enum.map(fn f -> {:top, f} end)

    (bottom_points ++ top_points)
    |> Enum.sort(fn {_, f1}, {_, f2} -> f1.open_time <= f2.open_time end)
    |> generate([[], [], []])
    |> Enum.map(&Enum.reverse/1)
  end

  def generate([], l), do: l

  def generate([{:bottom, frame} | points], [all, bottom, top]) do
    sp = %StrongPoint{
      frame: frame,
      point: %Geo.Point{coordinates: {frame.index, frame.low}},
      strength: frame.bottom_dominion,
      prev_top: List.first(top),
      prev_bottom: List.first(bottom),
      prev: List.first(all)
    }

    generate(points, [[sp | all], [sp | bottom], top])
  end

  def generate([{:top, frame} | points], [all, bottom, top]) do
    sp = %StrongPoint{
      frame: frame,
      point: %Geo.Point{coordinates: {frame.index, frame.high}},
      strength: frame.top_dominion,
      prev_top: List.first(top),
      prev_bottom: List.first(bottom),
      prev: List.first(all)
    }

    generate(points, [[sp | all], bottom, [sp | top]])
  end
end
