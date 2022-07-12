import Config

config :logger, level: :debug

config :ex_price_aggregator,
  exchanges: [ExPriceAggregator.Binance, ExPriceAggregator.Huobi, ExPriceAggregator.Kraken]