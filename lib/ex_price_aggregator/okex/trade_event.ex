defmodule ExPriceAggregator.Okex.TradeEvent do
  @moduledoc """
  Documentation: https://www.okx.com/docs-v5/en/#order-book-trading-market-data-ws-trades-channel
  """
  @enforce_keys [:instrument_id, :trade_id, :price, :size, :side, :timestamp, :count]
  defstruct @enforce_keys

  def new(raw_payload) when is_map(raw_payload) do
    %__MODULE__{
      instrument_id: raw_payload["instId"],
      trade_id: raw_payload["tradeId"],
      price: Decimal.new(raw_payload["px"]),
      size: Decimal.new(raw_payload["sz"]),
      side: raw_payload["side"],
      timestamp: raw_payload["ts"],
      count: raw_payload["count"]
    }
  end
end
