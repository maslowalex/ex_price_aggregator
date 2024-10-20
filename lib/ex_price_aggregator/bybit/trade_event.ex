defmodule ExPriceAggregator.Bybit.TradeEvent do
  alias Decimal, as: D

  defstruct [:ts, :symbol, :side, :volume, :price]

  alias ExPriceAggregator.Bybit.TradeEvent

  def parse!(raw) when is_list(raw) do
    %TradeEvent{
      ts: raw |> Enum.at(0) |> parse_ts(),
      symbol: Enum.at(raw, 1),
      side: raw |> Enum.at(2) |> side(),
      volume: raw |> Enum.at(3) |> D.new(),
      price: raw |> Enum.at(4) |> parse_price()
    }
  end

  defp side("Buy") do
    :buy
  end

  defp side("Sell") do
    :sell
  end

  defp parse_price(price) do
    D.Context.with(%D.Context{D.Context.get() | precision: 3}, fn ->
      D.new(price)
    end)
  end

  defp parse_ts(ts) do
    case String.split(ts, ".") do
      [ts, _] -> do_parse_ts(ts)
      [ts] -> do_parse_ts(ts)
    end
  end

  defp do_parse_ts(ts) do
    ts
    |> String.to_integer()
    |> DateTime.from_unix!()
  end
end
