defmodule ExPriceAggregator do
  @moduledoc """
  Documentation for `ExPriceAggregator`.
  """

  def aggregate(symbol) do
    [ExPriceAggregator.Binance, ExPriceAggregator.Huobi, ExPriceAggregator.Kraken]
    |> Enum.each(fn aggregator_mod -> aggregator_mod.start_link(symbol) end)
  end
end
