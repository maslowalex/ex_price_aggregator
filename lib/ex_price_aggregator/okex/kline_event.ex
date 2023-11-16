defmodule ExPriceAggregator.Okex.KlineEvent do
  @enforce_keys [:ts, :open, :high, :low, :close, :volCcyQuote, :volCcy, :vol, :confirm]
  defstruct @enforce_keys

  def attributes, do: @enforce_keys

  def new(attrs) do
    attrs
    |> Enum.map(
      &(Enum.zip_with(
          [attributes(), &1],
          fn
            [:ts, y] ->
              {:ts, String.to_integer(y)}

            [x, y] ->
              {x, Decimal.new(y)}
          end
        )
        |> Enum.into(%{}))
    )
  end
end
