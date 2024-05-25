defmodule ExPriceAggregator.Binance.WebsocketFeed do
  use WebSockex

  require Logger

  alias ExPriceAggregator.PubSub

  alias ExPriceAggregator.Binance.TradeEvent

  defmodule State do
    defstruct [:symbol, :timeframe, :type]
  end

  @stream_endpoint "wss://stream.binance.com:9443/ws/"

  def start_link(opts) do
    base = Keyword.fetch!(opts, :base)
    quote_c = Keyword.fetch!(opts, :quote)
    type = Keyword.get(opts, :type, :trades)
    timeframe = Keyword.get(opts, :timeframe)
    symbol = ExPriceAggregator.symbol(base, quote_c)
    state = %State{symbol: symbol, timeframe: timeframe, type: type}

    start_socket(state)
  end

  def handle_frame({_type, msg}, state) do
    case Jason.decode(msg) do
      {:ok, event} -> handle_event(event, state)
      {:error, _} -> throw("Unable to parse msg: #{msg}")
    end

    {:ok, state}
  end

  def handle_event(%{"e" => "trade"} = event, state) do
    trade_event = TradeEvent.new(event)

    Logger.debug(
      "Trade event received " <>
        "binance:#{state.symbol}@#{trade_event.price}"
    )

    PubSub.broadcast_trade(:binance, state.symbol, trade_event)
  end

  def handle_event(%{"e" => "kline", "k" => event}, state) do
    kline_event =
      event
      |> ExPriceAggregator.Binance.KlineEvent.new()
      |> ExPriceAggregator.Binance.KlineEvent.to_generic()

    Logger.debug(
      "Candle update received for tf: #{state.timeframe} " <>
        "binance:#{state.symbol}@#{kline_event.close}"
    )

    PubSub.broadcast_candle(:binance, state.symbol, kline_event, state.timeframe)
  end

  def handle_event(%{"ping" => payload}, state) do
    Logger.notice("Received ping: #{payload}")

    frame = {:text, Jason.encode!(%{pong: payload})}

    {:reply, frame, state}
  end

  defp start_socket(%State{type: :trades, symbol: symbol} = state) do
    WebSockex.start_link(
      "#{@stream_endpoint}#{String.downcase(symbol)}@trade",
      __MODULE__,
      state,
      name: ExPriceAggregator.via_tuple(:binance, symbol, :trades)
    )
  end

  defp start_socket(%State{type: :candles, symbol: symbol, timeframe: tf} = state) do
    WebSockex.start_link(
      "#{@stream_endpoint}#{String.downcase(symbol)}@kline_#{tf}",
      __MODULE__,
      state,
      name: ExPriceAggregator.via_tuple(:binance, symbol, :trades, tf)
    )
  end
end
