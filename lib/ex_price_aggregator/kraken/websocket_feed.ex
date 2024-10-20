defmodule ExPriceAggregator.Kraken.WebsocketFeed do
  use WebSockex

  require Logger

  alias ExPriceAggregator.PubSub

  alias ExPriceAggregator.Kraken.TradeEvent

  @stream_endpoint "wss://ws.kraken.com"

  def start_link(opts \\ []) do
    base = Keyword.fetch!(opts, :base)
    quote_c = Keyword.fetch!(opts, :quote)
    type = Keyword.get(opts, :type, :trades)
    symbol = ExPriceAggregator.symbol(base, quote_c)

    {:ok, pid} =
      WebSockex.start_link(
        "#{@stream_endpoint}",
        __MODULE__,
        symbol,
        name: ExPriceAggregator.via_tuple(:kraken, symbol, type)
      )

    kraken_name = symbol |> String.upcase() |> String.replace_suffix("USDT", "/USD")
    WebSockex.send_frame(pid, {:text, subscritpion_payload(type, kraken_name)})

    {:ok, pid}
  end

  def handle_frame({_type, msg}, state) do
    case Jason.decode(msg) do
      {:ok, event} -> handle_event(event, state)
      {:error, _} -> throw("Unable to parse msg: #{msg}")
    end

    {:ok, state}
  end

  def handle_event([_, trades, "trade", _] = _event, state) do
    trades
    |> Enum.map(fn trade ->
      trade_event = TradeEvent.new(trade)

      Logger.debug(
        "Trade event received " <>
          "kraken:#{state}@#{trade_event.price}"
      )

      PubSub.broadcast_trade(:kraken, state, trade_event)
    end)

    {:ok, state}
  end

  def handle_event(_event, state) do
    {:ok, state}
  end

  defp subscritpion_payload(:trades, pair) do
    %{
      event: "subscribe",
      pair: [pair],
      subscription: %{
        name: "trade"
      }
    }
    |> Jason.encode!()
  end
end
