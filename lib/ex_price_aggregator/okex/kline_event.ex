defmodule ExPriceAggregator.Okex.KlineEvent do
  @enforce_keys [:ts, :open, :high, :low, :close, :volCcyQuote, :volCcy, :vol, :confirm]
  defstruct @enforce_keys

  def attributes, do: @enforce_keys

  def to_generic(attrs) do
    %ExPriceAggregator.KlineEvent{
      ts: attrs.ts,
      open: attrs.open,
      high: attrs.high,
      low: attrs.low,
      close: attrs.close,
      vol_quote: attrs.volCcyQuote,
      vol_currency: attrs.volCcy,
      vol: attrs.vol,
      finished: attrs.confirm,
      exchange: :okex
    }
  end

  def new(attrs) when is_list(attrs) do
    Enum.zip_with(
      [@enforce_keys, attrs],
      fn
        [:ts, y] ->
          {:ts, String.to_integer(y)}

        [:confirm, y] ->
          {:confirm, y == "1"}

        [x, y] ->
          {x, Decimal.new(y)}
      end
    )
    |> Enum.into(%{})
    |> to_generic()
  end
end
