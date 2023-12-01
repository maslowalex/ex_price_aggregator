defmodule ExPriceAggregator.Binance.TradeEvent do
  @enforce_keys [
    :event_type,
    :event_time,
    :symbol,
    :trade_id,
    :price,
    :quantity,
    :buyer_order_id,
    :seller_order_id,
    :trade_time,
    :buyer_market_maker
  ]

  defstruct @enforce_keys

  def new(attributes) when is_map(attributes) do
    %__MODULE__{
      event_type: attributes["e"],
      event_time: attributes["E"],
      symbol: attributes["s"],
      trade_id: attributes["t"],
      price: Decimal.new(attributes["p"]),
      quantity: attributes["q"],
      buyer_order_id: attributes["b"],
      seller_order_id: attributes["a"],
      trade_time: attributes["T"],
      buyer_market_maker: attributes["m"]
    }
  end
end
