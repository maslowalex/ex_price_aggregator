defmodule ExPriceAggregator.Binance.WebsocketFeed do
  use Fresh

  require Logger

  alias ExPriceAggregator.PubSub

  alias ExPriceAggregator.Binance.TradeEvent

  defmodule State do
    defstruct [:symbol, :timeframes, :type]
  end

  @stream_base "wss://stream.binance.com:9443/ws/"

  def start_link(opts) do
    base = Keyword.fetch!(opts, :base)
    quote_c = Keyword.fetch!(opts, :quote)
    type = Keyword.get(opts, :type, :trades)
    timeframe = Keyword.get(opts, :timeframe)
    symbol = ExPriceAggregator.symbol(base, quote_c)
    state = %State{symbol: symbol, type: type, timeframes: [timeframe]}

    start_socket(state)
  end

  def handle_control({:ping, message}, state) do
    {:reply, {:pong, message}, state}
  end

  def handle_control({:pong, _}, state) do
    {:ok, state}
  end

  def handle_connect(_params, state) do
    {:ok, state}
  end

  def handle_in({:text, msg}, state) do
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

    :ok = PubSub.broadcast_trade(:binance, state.symbol, trade_event)

    {:ok, state}
  end

  def handle_event(%{"e" => "kline", "k" => event}, state) do
    kline_event =
      event
      |> ExPriceAggregator.Binance.KlineEvent.new()
      |> ExPriceAggregator.Binance.KlineEvent.to_generic()

    Logger.debug(
      "Candle update received for tf: #{event["i"]} " <>
        "binance:#{state.symbol}@#{kline_event.close}"
    )

    :ok = PubSub.broadcast_candle(:binance, state.symbol, kline_event, event["i"])

    {:ok, state}
  end

  def handle_event(event, state) do
    Logger.warning("Unhandled event: #{inspect(event)}")

    {:ok, state}
  end

  def handle_disconnect(1000, _, _), do: :close

  def handle_disconnect(code, reason, state) do
    Logger.warning("Disconnected from binance websocket: #{code} - #{reason}")

    {:reconnect, state}
  end

  def handle_error(error, state) do
    Logger.error("Error in binance websocket: #{inspect(error)}")

    {:reconnect, state}
  end

  def handle_info(:terminate, state) do
    Logger.info("Terminating the worker #{inspect(state)}")

    {:close, 1000, "User requested", state}
  end

  def handle_info({:subscribe, timeframes}, state) when is_list(timeframes) do
    subscription_message = %{
      method: "SUBSCRIBE",
      params: timeframes_to_params(timeframes, state.symbol),
      id: state.symbol
    }

    new_timeframes = MapSet.new(timeframes ++ state.timeframes)
    new_state = %{state | timeframes: MapSet.to_list(new_timeframes)}

    {:reply, [{:text, Jason.encode!(subscription_message)}], new_state}
  end

  defp start_socket(%State{type: :trades, symbol: symbol} = state) do
    Fresh.start_link(
      "#{@stream_base}#{String.downcase(symbol)}@trade",
      __MODULE__,
      state,
      name: ExPriceAggregator.via_tuple(:binance, symbol, :trades),
      ping_interval: 0
    )
  end

  defp start_socket(%State{type: :candles, symbol: symbol, timeframes: [tf]} = state) do
    endpoint = symbol_timeframe_endpoint(symbol, tf)

    Fresh.start_link(
      "#{@stream_base}#{endpoint}",
      __MODULE__,
      state,
      name: ExPriceAggregator.via_tuple(:binance, symbol),
      backoff_initial: 2_500,
      ping_interval: 0
    )
  end

  defp symbol_timeframe_endpoint(symbol, tf) do
    "#{String.downcase(symbol)}@kline_#{tf}"
  end

  defp timeframes_to_params(timeframes, symbol) do
    Enum.map(timeframes, &symbol_timeframe_endpoint(symbol, &1))
  end
end
