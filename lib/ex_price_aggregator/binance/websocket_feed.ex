defmodule ExPriceAggregator.Binance.WebsocketFeed do
  use WebSockex

  require Logger

  alias ExPriceAggregator.PubSub

  @stream_endpoint "wss://stream.binance.com:9443/ws/"

  def start_link(opts) do
    base = Keyword.fetch!(opts, :base)
    quote_c = Keyword.fetch!(opts, :quote)
    type = Keyword.get(opts, :type, :trades)

    symbol = ExPriceAggregator.symbol(base, quote_c)

    WebSockex.start_link(
      "#{@stream_endpoint}#{String.downcase(symbol)}@trade",
      __MODULE__,
      symbol,
      name: ExPriceAggregator.via_tuple(:binance, symbol, type)
    )
  end

  def handle_frame({_type, msg}, state) do
    case Jason.decode(msg) do
      {:ok, event} -> handle_event(event, state)
      {:error, _} -> throw("Unable to parse msg: #{msg}")
    end

    {:ok, state}
  end

  def handle_event(%{"e" => "trade"} = event, state) do
    {price, _} = Float.parse(event["p"])

    trade_event = %ExPriceAggregator.Binance.TradeEvent{
      event_type: event["e"],
      event_time: event["E"],
      symbol: event["s"],
      trade_id: event["t"],
      price: price,
      quantity: event["q"],
      buyer_order_id: event["b"],
      seller_order_id: event["a"],
      trade_time: event["T"],
      buyer_market_maker: event["m"]
    }

    Logger.debug(
      "Trade event received " <>
        "binance:#{state}@#{trade_event.price}"
    )

    PubSub.broadcast_trade(:binance, state, trade_event)
  end
end
