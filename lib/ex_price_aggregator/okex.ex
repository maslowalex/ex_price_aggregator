defmodule ExPriceAggregator.Okex do
  use WebSockex

  require Logger

  alias ExPriceAggregator.PubSub

  defmodule State do
    defstruct [:symbol, :native_symbol]
  end

  @stream_endpoint "wss://ws.okx.com:8443/ws/v5/public"

  def start_link(opts) do
    base = Keyword.fetch!(opts, :base)
    quote_c = Keyword.fetch!(opts, :quote)
    type = Keyword.get(opts, :type, :trades)

    symbol = ExPriceAggregator.symbol(base, quote_c)
    instrument = Enum.map_join([base, quote_c], "-", &String.upcase/1)

    {:ok, pid} =
      WebSockex.start_link(
        @stream_endpoint,
        __MODULE__,
        %State{symbol: symbol, native_symbol: instrument},
        name: ExPriceAggregator.via_tuple(__MODULE__, symbol, type)
      )

    subscription_message = Jason.encode!(subscription_message(type, instrument))

    WebSockex.send_frame(pid, {:text, subscription_message})

    {:ok, pid}
  end

  def handle_frame({type, msg}, state) do
    case Jason.decode(msg) do
      {:ok, %{"event" => "subscribe"}} ->
        Logger.info("[#{__MODULE__}] Successfully subscribed to #{state.native_symbol}")

      {:ok, %{"arg" => %{"channel" => "trades"}, "data" => trades_list}} ->
        for raw_event <- trades_list do
          trade_event = ExPriceAggregator.Okex.TradeEvent.new(raw_event)

          Logger.info("Trade event received okex:#{state.symbol}@#{trade_event.price}")

          PubSub.broadcast_trade(:okex, state.symbol, trade_event)
        end

      {:ok, unhandled} ->
        Logger.debug("Unhandled message: #{inspect(unhandled)}")

      {:error, _} ->
        throw("Unable to parse msg: #{msg}")
    end

    {:ok, state}
  end

  def terminate(reason, instrument) do
    Logger.debug(
      "Stopping the aggregation for: #{instrument} on OKex. Reason: #{inspect(reason)}"
    )
  end

  def subscription_message(:candles, instrument) do
    %{
      "op" => "subscribe",
      "args" => [
        %{
          "channel" => "candle1m",
          "instId" => instrument
        }
      ]
    }
  end

  def subscription_message(:trades, instrument) do
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
end
