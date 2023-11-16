defmodule ExPriceAggregator do
  @moduledoc """
  Documentation for `ExPriceAggregator`.
  """

  @doc """
  Spawns a process that would subscribe to the trades channel of the exchange
  """
  def track_trades(exchange, base_currency, quote_currency) do
    exchange = Application.fetch_env!(:ex_price_aggregator, :exchanges) |> Map.fetch!(exchange)

    child_spec = %{
      id: exchange,
      start: {exchange, :start_link, [[base: base_currency, quote: quote_currency]]}
    }

    DynamicSupervisor.start_child(ExPriceAggregator.DynamicSupervisor, child_spec)
  end

  @doc """
  Spawns a process that would subscribe to the ticks channel of the exchange
  """
  def track_ticks(exchange, base_currency, quote_currency) do
    # https://www.okx.com/docs-v5/en/#order-book-trading-market-data-ws-candlesticks-channel
    exchange = Application.fetch_env!(:ex_price_aggregator, :exchanges) |> Map.fetch!(exchange)

    child_spec = %{
      id: exchange,
      start: {exchange, :start_link, [[base: base_currency, quote: quote_currency, type: :ticks]]}
    }

    DynamicSupervisor.start_child(ExPriceAggregator.DynamicSupervisor, child_spec)
  end

  def untrack_trades(exchange, base_currency, quote_currency) do
    exchange = Application.fetch_env!(:ex_price_aggregator, :exchanges) |> Map.fetch!(exchange)
    symbol = ExPriceAggregator.symbol(base_currency, quote_currency)
    pid = Process.whereis(ExPriceAggregator.via_tuple(exchange, symbol, :trades))

    DynamicSupervisor.terminate_child(ExPriceAggregator.DynamicSupervisor, pid)
  end

  def via_tuple(exchange, symbol) do
    {:via, Registry, {ExPriceAggregator.ExchangeRegistry, "#{exchange}@#{symbol}"}}
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
end
