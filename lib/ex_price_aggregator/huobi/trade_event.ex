defmodule ExPriceAggregator.Huobi.TradeEvent do
  defstruct [
    :open,
    :high,
    :low,
    :close,
    :amount,
    :vol,
    :count,
    :bid,
    :bid_size,
    :ask,
    :ask_size,
    :last_price,
    :last_size
  ]
end
