defmodule ExPriceAggregator.Huobi do
  use WebSockex

  require Logger

  @stream_endpoint "wss://api.huobi.pro/ws"

  def start_link(symbol) do
    {:ok, pid} =
      WebSockex.start_link(
        "#{@stream_endpoint}",
        __MODULE__,
        symbol,
        name: ExPriceAggregator.via_tuple(__MODULE__, symbol)
      )

    WebSockex.send_frame(
      pid,
      {:text, Jason.encode!(%{sub: "market.#{symbol}.ticker", id: "exid-1"})}
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

  def handle_event(%{"status" => "ok"}, symbol) do
    Logger.info("[Huobi] Successfully connected to #{symbol} stream")

    {:ok, symbol}
  end

  def handle_event(%{"ch" => _topic, "tick" => event}, symbol) do
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
        "huobi:#{symbol}@#{trade_event.last_price}"
    )

    Phoenix.PubSub.broadcast(
      ExPriceAggregator.PubSub,
      "trade:huobi:#{symbol}",
      trade_event
    )

    {:ok, symbol}
  end

  def handle_event(%{"ping" => timestamp}, state) do
    frame = {:text, Jason.encode!(%{pong: timestamp})}

    {:reply, frame, state}
  end
end
