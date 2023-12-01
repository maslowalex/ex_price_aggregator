defmodule ExPriceAggregator.Okex do
  @moduledoc """
  API to interact with Okex exchange
  """

  @behaviour ExPriceAggregator.ExchangeIntegration

  alias ExPriceAggregator.Okex

  def subscribe_to_feed(opts \\ []) do
    Okex.WebsocketFeed.start_link(opts)
  end

  def get_candles(base_currency, quote_currency, opts \\ []) do
    Okex.API.get_candles(base_currency, quote_currency, opts)
  end
end
