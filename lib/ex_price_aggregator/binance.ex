defmodule ExPriceAggregator.Binance do
  use WebSockex

  require Logger

  @stream_endpoint "wss://stream.binance.com:9443/ws/"

  def start_link(symbol) do
    WebSockex.start_link(
      "#{@stream_endpoint}#{symbol}@trade",
      __MODULE__,
      symbol
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
    trade_event = %ExPriceAggregator.Binance.TradeEvent{
      event_type: event["e"],
      event_time: event["E"],
      symbol: event["s"],
      trade_id: event["t"],
      price: event["p"],
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

    Phoenix.PubSub.broadcast(
      ExPriceAggregator.PubSub,
      "trade:binance:#{state}",
      trade_event
    )
  end
end
