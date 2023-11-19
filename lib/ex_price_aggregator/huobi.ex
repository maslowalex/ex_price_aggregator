defmodule ExPriceAggregator.Huobi do
  @behaviour ExPriceAggregator.ExchangeIntegration

  alias ExPriceAggregator.Huobi

  def subscribe_to_feed(opts \\ []) do
    Huobi.WebsocketFeed.start_link(opts)
  end
end
