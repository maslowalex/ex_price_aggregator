defmodule ExPriceAggregator.ExchangeIntegration do
  @type currency() :: String.t()
  @type type() :: :trades | :ticks

  @callback subscribe_to_feed([{:base, currency()}, {:quote, currency()}, {:type, type()}]) :: :ok
end
