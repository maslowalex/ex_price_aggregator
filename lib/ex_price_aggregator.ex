defmodule ExPriceAggregator do
  @moduledoc """
  Documentation for `ExPriceAggregator`.
  """

  @doc """
  Spawns a process that would subscribe to the trades channel of the exchange
  """
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
  Spawns a process that would subscribe to the ticks channel of the exchange
  """
  def track_ticks(exchange, base_currency, quote_currency) do
    # https://www.okx.com/docs-v5/en/#order-book-trading-market-data-ws-candlesticks-channel
    exchange_mod = supported_exchanges() |> Map.fetch!(exchange)
    symbol = ExPriceAggregator.symbol(base_currency, quote_currency)

    child_spec = %{
      id: "#{exchange}:#{symbol}:ticks",
      start:
        {exchange_mod, :subscribe_to_feed,
         [[base: base_currency, quote: quote_currency, type: :ticks]]}
    }

    DynamicSupervisor.start_child(ExPriceAggregator.DynamicSupervisor, child_spec)
  end

  def untrack_trades(exchange, base_currency, quote_currency) do
    symbol = ExPriceAggregator.symbol(base_currency, quote_currency)

    case Registry.lookup(ExPriceAggregator.ExchangeRegistry, "#{exchange}@#{symbol}@trades") do
      [{pid, _}] ->
        DynamicSupervisor.terminate_child(ExPriceAggregator.DynamicSupervisor, pid)

      [] ->
        :no_proc
    end
  end

  def via_tuple(exchange, symbol, type) do
    {:via, Registry, {ExPriceAggregator.ExchangeRegistry, "#{exchange}@#{symbol}@#{type}"}}
  end

  @doc """
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
