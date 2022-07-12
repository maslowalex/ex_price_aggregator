defmodule ExPriceAggregator do
  @moduledoc """
  Documentation for `ExPriceAggregator`.
  """

  def aggregate(symbol) do
    :ex_price_aggregator
    |> Application.get_env(:exchanges)
    |> Enum.each(fn exchange ->
      child_spec = %{
        id: exchange,
        start: {exchange, :start_link, [symbol]}
      }

      DynamicSupervisor.start_child(ExPriceAggregator.DynamicSupervisor, child_spec)
    end)
  end

  def via_tuple(exchange, symbol) do
    {:via, Registry, {ExPriceAggregator.ExchangeRegistry, "#{exchange}@#{symbol}"}}
  end
end
