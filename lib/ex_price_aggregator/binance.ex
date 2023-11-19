defmodule ExPriceAggregator.Binance do
  @behaviour ExPriceAggregator.ExchangeIntegration

  alias ExPriceAggregator.Binance

  def subscribe_to_feed(opts \\ []) do
    Binance.WebsocketFeed.start_link(opts)
  end
end
