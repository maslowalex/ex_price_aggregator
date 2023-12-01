defmodule ExPriceAggregator.Okex.WebsocketFeed do
  use WebSockex

  require Logger

  alias ExPriceAggregator.PubSub

  defmodule State do
    defstruct [:symbol, :native_symbol, :type, :timeframe]
  end

  @stream_endpoint "wss://ws.okx.com:8443/ws/v5/public"

  def start_link(opts) do
    base = Keyword.fetch!(opts, :base)
    quote_c = Keyword.fetch!(opts, :quote)
    type = Keyword.get(opts, :type, :trades)
    timeframe = Keyword.get(opts, :timeframe, "1m")

    symbol = ExPriceAggregator.symbol(base, quote_c)
    instrument = Enum.map_join([base, quote_c], "-", &String.upcase/1)

    {:ok, pid} =
      WebSockex.start_link(
        # Should be different for klines (private)
        @stream_endpoint,
        __MODULE__,
        %State{symbol: symbol, native_symbol: instrument, type: type, timeframe: timeframe},
        name: server_name(symbol, type, timeframe)
      )

    subscription_message = Jason.encode!(subscription_message(type, instrument, opts))

    WebSockex.send_frame(pid, {:text, subscription_message})

    {:ok, pid}
  end

  def handle_frame({_, msg}, state) do
    case Jason.decode(msg) do
      {:ok, %{"event" => "subscribe"}} ->
        Logger.info("[#{__MODULE__}] Successfully subscribed to #{state.native_symbol}")

      {:ok, %{"arg" => %{"channel" => "trades"}, "data" => trades_list}} ->
        for raw_event <- trades_list do
          trade_event = ExPriceAggregator.Okex.TradeEvent.new(raw_event)

          Logger.debug(
            "Trade event received " <>
              "okex:#{state.symbol}@#{trade_event.price}"
          )

          PubSub.broadcast_trade(:okex, state.symbol, trade_event)
        end

      {:ok, %{"arg" => %{"channel" => "candle" <> tf}, "data" => candles_list}} ->
        for candle_update <- candles_list do
          kline_update = ExPriceAggregator.Okex.KlineEvent.new(candle_update)

          Logger.debug(
            "Candle update received for tf: #{tf}" <>
              "okex:#{state.symbol}@#{kline_update.vol}"
          )

          PubSub.broadcast_candle(:okex, state.symbol, kline_update, tf)
        end

      {:ok, unhandled} ->
        Logger.debug("Unhandled message: #{inspect(unhandled)}")

      {:error, _} ->
        throw("Unable to parse msg: #{msg}")
    end

    {:ok, state}
  end

  def terminate(reason, state) do
    Logger.debug(
      "Stopping the aggregation for: #{state.native_symbol} on OKex. Reason: #{inspect(reason)}"
    )

    WebSockex.send_frame(self(), {:text, unsubscribe_message(state.native_symbol, state.type)})
  end

  def subscription_message(:candles, instrument, opts) do
    tf = Keyword.get(opts, :timeframe, "1m")

    %{
      "op" => "subscribe",
      "args" => [
        %{
          "channel" => "candle" <> tf,
          "instId" => instrument
        }
      ]
    }
  end

  def subscription_message(:trades, instrument, _) do
    %{
      "op" => "subscribe",
      "args" => [
        %{
          "channel" => "trades",
          "instId" => instrument
        }
      ]
    }
  end

  def unsubscribe_message(instrument, channel) do
    %{
      "op" => "unsubscribe",
      "args" => [
        %{
          "channel" => channel,
          "instId" => instrument
        }
      ]
    }
  end

  defp server_name(symbol, :trades, _timeframe) do
    ExPriceAggregator.via_tuple(:okex, symbol, :trades)
  end

  defp server_name(symbol, type, timeframe) do
    ExPriceAggregator.via_tuple(:okex, symbol, type, timeframe)
  end
end
