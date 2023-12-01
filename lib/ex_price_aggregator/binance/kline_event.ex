defmodule ExPriceAggregator.Binance.KlineEvent do
  # "t": 123400000, // Kline start time
  # "T": 123460000, // Kline close time
  # "s": "BNBBTC",  // Symbol
  # "i": "1m",      // Interval
  # "f": 100,       // First trade ID
  # "L": 200,       // Last trade ID
  # "o": "0.0010",  // Open price
  # "c": "0.0020",  // Close price
  # "h": "0.0025",  // High price
  # "l": "0.0015",  // Low price
  # "v": "1000",    // Base asset volume
  # "n": 100,       // Number of trades
  # "x": false,     // Is this kline closed?
  # "q": "1.0000",  // Quote asset volume
  # "V": "500",     // Taker buy base asset volume
  # "Q": "0.500",   // Taker buy quote asset volume
  # "B": "123456"   // Ignore
  defstruct [
    :start_time,
    :close_time,
    :symbol,
    :interval,
    :first_trade_id,
    :last_trade_id,
    :open_price,
    :close_price,
    :high_price,
    :low_price,
    :base_asset_volume,
    :number_of_trades,
    :is_kline_closed,
    :quote_asset_volume,
    :taker_buy_base_asset_volume,
    :taker_buy_quote_asset_volume
  ]

  def new(attributes) when is_map(attributes) do
    %__MODULE__{
      start_time: attributes["t"],
      close_time: attributes["T"],
      symbol: attributes["s"],
      interval: attributes["i"],
      first_trade_id: attributes["f"],
      last_trade_id: attributes["L"],
      open_price: Decimal.new(attributes["o"]),
      close_price: Decimal.new(attributes["c"]),
      high_price: Decimal.new(attributes["h"]),
      low_price: Decimal.new(attributes["l"]),
      base_asset_volume: Decimal.new(attributes["v"]),
      number_of_trades: attributes["n"],
      is_kline_closed: attributes["x"],
      quote_asset_volume: Decimal.new(attributes["q"]),
      taker_buy_base_asset_volume: Decimal.new(attributes["V"]),
      taker_buy_quote_asset_volume: Decimal.new(attributes["Q"])
    }
  end

  # [
  #   1499040000000,      // Kline open time
  #   "0.01634790",       // Open price
  #   "0.80000000",       // High price
  #   "0.01575800",       // Low price
  #   "0.01577100",       // Close price
  #   "148976.11427815",  // Volume
  #   1499644799999,      // Kline Close time
  #   "2434.19055334",    // Quote asset volume
  #   308,                // Number of trades
  #   "1756.87402397",    // Taker buy base asset volume
  #   "28.46694368",      // Taker buy quote asset volume
  #   "0"                 // Unused field, ignore.
  # ]
  def new(attrs) when is_list(attrs) do
    %__MODULE__{
      start_time: Enum.at(attrs, 0),
      open_price: attrs |> Enum.at(1) |> Decimal.new(),
      high_price: attrs |> Enum.at(2) |> Decimal.new(),
      low_price: attrs |> Enum.at(3) |> Decimal.new(),
      close_price: attrs |> Enum.at(4) |> Decimal.new(),
      base_asset_volume: attrs |> Enum.at(5) |> Decimal.new(),
      close_time: Enum.at(attrs, 6),
      quote_asset_volume: attrs |> Enum.at(7) |> Decimal.new(),
      number_of_trades: Enum.at(attrs, 8),
      taker_buy_base_asset_volume: attrs |> Enum.at(9) |> Decimal.new(),
      taker_buy_quote_asset_volume: attrs |> Enum.at(10) |> Decimal.new(),
      is_kline_closed: true
    }
  end

  def to_generic(attrs) do
    %ExPriceAggregator.KlineEvent{
      ts: attrs.start_time,
      open: attrs.open_price,
      high: attrs.high_price,
      low: attrs.low_price,
      close: attrs.close_price,
      vol_quote: attrs.taker_buy_base_asset_volume,
      vol_currency: attrs.taker_buy_quote_asset_volume,
      vol: attrs.quote_asset_volume,
      finished: attrs.is_kline_closed,
      exchange: :binance
    }
  end
end
