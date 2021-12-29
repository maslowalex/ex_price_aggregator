defmodule ExPriceAggregator.Kraken.TradeEvent do
  defstruct [
    :price,
    :volume,
    :time,
    :side,
    :order_type,
    :misc
  ]
end
