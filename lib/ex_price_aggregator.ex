defmodule ExPriceAggregator do
  @moduledoc """
  Documentation for `ExPriceAggregator`.
  """

  @type exchange :: :okex | :binance | :huobi | :kraken
  @type currency :: String.t()
  @type limit :: pos_integer()
  @type timeframe ::
          :"1m" | :"3m" | :"5m" | :"15m" | :"30m" | :"1h" | :"2h" | :"4h" | :"6h" | :"12h" | :"1d"

  @doc """
  Get specified amount of candles from given exchange.
  Supported options:
    * `:limit` - amount of candles to fetch, defaults to 100
    * `:timeframe` - timeframe of candles, defaults to :"1m"

  Example:
    `ExPriceAggregator.get_candles(:okex, "btc", "usdt", [limit: 200, timeframe: :"1m"])`
  """
  def get_candles(exchange, base_currency, quote_currency, opts \\ []) do
    exchange = supported_exchanges() |> Map.fetch!(exchange)
    opts = opts |> Keyword.put_new(:limit, 200) |> Keyword.put_new(:timeframe, :"1m")

    exchange.get_candles(base_currency, quote_currency, opts)
  end

  @doc """
  Spawns a process that would subscribe to the trades channel of the exchange
  """
  @spec track_trades(exchange, currency, currency) :: DynamicSupervisor.on_start_child()
  def track_trades(exchange, base_currency, quote_currency) do
    exchange = supported_exchanges() |> Map.fetch!(exchange)
    symbol = ExPriceAggregator.symbol(base_currency, quote_currency)

    child_spec = %{
      id: "#{exchange}:#{symbol}:trades",
      start: {exchange, :subscribe_to_feed, [[base: base_currency, quote: quote_currency]]}
    }

    DynamicSupervisor.start_child(ExPriceAggregator.DynamicSupervisor, child_spec)
  end

  @doc """
  Spawns a process that would subscribe to the candles channel of the exchange
  """
  @spec track_candles(exchange, currency, currency) :: DynamicSupervisor.on_start_child()
  def track_candles(exchange, base_currency, quote_currency, tf \\ "1m") do
    # https://www.okx.com/docs-v5/en/#order-book-trading-market-data-ws-candlesticks-channel
    exchange_mod = supported_exchanges() |> Map.fetch!(exchange)
    symbol = ExPriceAggregator.symbol(base_currency, quote_currency)

    child_spec = %{
      id: "#{exchange}:#{symbol}:candles#{tf}",
      start:
        {exchange_mod, :subscribe_to_feed,
         [[base: base_currency, quote: quote_currency, type: :candles, timeframe: tf]]}
    }

    DynamicSupervisor.start_child(ExPriceAggregator.DynamicSupervisor, child_spec)
  end

  @doc """
  Finds and kills the process that is subscribed to the trades channel of the exchange.
  """
  @spec untrack_trades(exchange, currency, currency) :: :ok | :noproc
  def untrack_trades(exchange, base_currency, quote_currency) do
    symbol = ExPriceAggregator.symbol(base_currency, quote_currency)

    case Registry.lookup(ExPriceAggregator.ExchangeRegistry, "#{exchange}@#{symbol}@trades") do
      [{pid, _}] ->
        DynamicSupervisor.terminate_child(ExPriceAggregator.DynamicSupervisor, pid)

      [] ->
        :noproc
    end
  end

  @doc """
  Finds and kills the process that is subscribed to the trades channel of the exchange.
  """
  @spec untrack_candles(exchange, currency, currency, timeframe()) :: :ok | :noproc
  def untrack_candles(exchange, base_currency, quote_currency, tf) do
    symbol = ExPriceAggregator.symbol(base_currency, quote_currency)

    case Registry.lookup(
           ExPriceAggregator.ExchangeRegistry,
           "#{exchange}@#{symbol}@candles@#{tf}"
         ) do
      [{pid, _}] ->
        DynamicSupervisor.terminate_child(ExPriceAggregator.DynamicSupervisor, pid)

      [] ->
        :noproc
    end
  end

  @doc """
  Unified way of building a `via` tuple for the registry.
  """
  def via_tuple(exchange, symbol, type) do
    {:via, Registry, {ExPriceAggregator.ExchangeRegistry, "#{exchange}@#{symbol}@#{type}"}}
  end

  def via_tuple(exchange, symbol, type, tf) do
    {:via, Registry, {ExPriceAggregator.ExchangeRegistry, "#{exchange}@#{symbol}@#{type}@#{tf}"}}
  end

  @doc """
  Transforms the given currency pair into a library-level token.

  iex> ExPriceAggregator.symbol("ada", "usdt")
  "ADAUSDT"
  """
  def symbol(base_currency, quote_currency) do
    [base_currency, quote_currency] |> Enum.map_join("", &String.upcase/1)
  end

  def supported_exchanges do
    %{
      okex: ExPriceAggregator.Okex,
      binance: ExPriceAggregator.Binance,
      huobi: ExPriceAggregator.Huobi,
      kraken: ExPriceAggregator.Kraken
    }
  end
end
