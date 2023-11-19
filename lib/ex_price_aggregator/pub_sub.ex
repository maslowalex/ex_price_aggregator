defmodule ExPriceAggregator.PubSub do
  @moduledoc false

  def broadcast_trade(exchange, symbol, trade_event) do
    Phoenix.PubSub.broadcast(
      ExPriceAggregator.PubSub,
      "trade:#{exchange}:#{symbol}",
      trade_event
    )
  end

  def broadcast_candle(exchange, symbol, candle_event) do
    Phoenix.PubSub.broadcast(
      ExPriceAggregator.PubSub,
      "candle:#{exchange}:#{symbol}",
      candle_event
    )
  end

  def subscribe_trades(exchange, base_currency, quote_currency) do
    symbol = ExPriceAggregator.symbol(base_currency, quote_currency)

    subscribe_trades(exchange, symbol)
  end

  def subscribe_trades(exchange, symbol) do
    Phoenix.PubSub.subscribe(
      ExPriceAggregator.PubSub,
      "trade:#{exchange}:#{symbol}"
    )
  end
end
