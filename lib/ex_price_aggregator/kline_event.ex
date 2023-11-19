defmodule ExPriceAggregator.KlineEvent do
  @moduledoc """
  Generic kline event representation
  """
  @enforce_keys [
    :ts,
    :open,
    :high,
    :low,
    :close,
    :vol_quote,
    :vol_currency,
    :vol,
    :finished,
    :exchange
  ]
  defstruct @enforce_keys
end
