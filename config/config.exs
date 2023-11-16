import Config

config :logger, level: :debug

config :ex_price_aggregator,
  exchanges: %{
    okex: ExPriceAggregator.Okex,
    binance: ExPriceAggregator.Binance,
    huobi: ExPriceAggregator.Huobi,
    kraken: ExPriceAggregator.Kraken
  }

# exchanges: [ExPriceAggregator.Binance, ExPriceAggregator.Huobi, ExPriceAggregator.Kraken]
