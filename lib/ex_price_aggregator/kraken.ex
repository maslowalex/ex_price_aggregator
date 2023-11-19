defmodule ExPriceAggregator.Kraken do
  @behaviour ExPriceAggregator.ExchangeIntegration

  alias ExPriceAggregator.Kraken

  def subscribe_to_feed(opts \\ []) do
    Kraken.WebsocketFeed.start_link(opts)
  end
end
