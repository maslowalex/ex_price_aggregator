defmodule ExPriceAggregator.Okex do
  @moduledoc """
  API to interact with Okex exchange
  """

  @behaviour ExPriceAggregator.ExchangeIntegration

  alias ExPriceAggregator.Okex

  alias ExPriceAggregator.RateLimiter

  def subscribe_to_feed(opts \\ []) do
    Okex.WebsocketFeed.start_link(opts)
  end

  def get_candles(base_currency, quote_currency, opts \\ []) do
    request = Okex.API.build_get_candles(base_currency, quote_currency, opts)

    RateLimiter.request(__MODULE__, request, Okex.API, :get_candles)
  end
end
