defmodule ExPriceAggregator.Kraken.TradeEvent do
  defstruct [
    :price,
    :volume,
    :time,
    :side,
    :order_type,
    :misc
  ]

  def new(attrs) when is_list(attrs) do
    %__MODULE__{
      price: attrs |> Enum.at(0) |> Decimal.from_float(),
      volume: attrs |> Enum.at(1) |> Decimal.new(),
      time: Enum.at(attrs, 2),
      side: Enum.at(attrs, 3),
      order_type: if(Enum.at(attrs, 4) == "b", do: :buy, else: :sell),
      misc: Enum.at(attrs, 5)
    }
  end
end
