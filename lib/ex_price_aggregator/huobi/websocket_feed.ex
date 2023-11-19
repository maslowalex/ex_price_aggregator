defmodule ExPriceAggregator.Huobi.WebsocketFeed do
  use WebSockex

  require Logger

  alias ExPriceAggregator.PubSub

  @stream_endpoint "wss://api.huobi.pro/ws"

  defmodule State do
    defstruct [:id, :symbol]
  end

  def start_link(opts) do
    base = Keyword.fetch!(opts, :base)
    quote_c = Keyword.fetch!(opts, :quote)
    type = Keyword.get(opts, :type, :trades)

    symbol = ExPriceAggregator.symbol(base, quote_c)

    state = %State{
      symbol: symbol,
      id: :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
    }

    {:ok, pid} =
      WebSockex.start_link(
        @stream_endpoint,
        __MODULE__,
        state,
        name: ExPriceAggregator.via_tuple(:huobi, symbol, type)
      )

    WebSockex.send_frame(
      pid,
      {:text, Jason.encode!(%{sub: "market.#{String.downcase(symbol)}.ticker", id: state.id})}
    )

    {:ok, pid}
  end

  def handle_frame({:binary, msg}, state) do
    msg = [msg] |> StreamGzip.gunzip() |> Enum.into("")

    case Jason.decode(msg) do
      {:ok, event} -> handle_event(event, state)
      {:error, _} -> throw("Unable to parse msg: #{msg}")
    end
  end

  def handle_event(%{"status" => "ok"}, state) do
    Logger.info("[Huobi] Successfully connected to #{state.symbol} stream")

    {:ok, state}
  end

  def handle_event(%{"ch" => _topic, "tick" => event}, state) do
    trade_event = %ExPriceAggregator.Huobi.TradeEvent{
      open: event["open"],
      high: event["high"],
      low: event["low"],
      close: event["close"],
      amount: event["amount"],
      vol: event["vol"],
      count: event["count"],
      bid: event["bid"],
      bid_size: event["bidSize"],
      ask: event["ask"],
      ask_size: event["askSize"],
      last_price: event["lastPrice"],
      last_size: event["lastSize"]
    }

    Logger.debug(
      "Trade event received " <>
        "huobi:#{state.symbol}@#{trade_event.last_price}"
    )

    PubSub.broadcast_trade(:huobi, state.symbol, trade_event)

    {:ok, state}
  end

  def handle_event(%{"ping" => timestamp}, state) do
    frame = {:text, Jason.encode!(%{pong: timestamp})}

    {:reply, frame, state}
  end
end
