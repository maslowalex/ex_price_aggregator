defmodule ExPriceAggregator.Binance do
  @behaviour ExPriceAggregator.ExchangeIntegration

  alias ExPriceAggregator.Binance

  def subscribe_to_feed(opts \\ []) do
    Binance.WebsocketFeed.start_link(opts)
  end

  def get_candles(base_currency, quote_currency, opts) do
    Binance.API.get_candles(base_currency, quote_currency, opts)
  end
end
