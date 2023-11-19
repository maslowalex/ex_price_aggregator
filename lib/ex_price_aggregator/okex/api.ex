defmodule ExPriceAggregator.Okex.Api do
  alias ExPriceAggregator.Okex.KlineEvent

  @endpoint "https://www.okx.com/api/v5/market/history-candles"

  def get_candles(base_currency, quote_currency) do
    build_get_candles(base_currency, quote_currency)
    |> Finch.request(ExPriceAggregator.Finch)
    |> case do
      {:ok, %Finch.Response{status: 200, body: json_response}} ->
        candles =
          Jason.decode!(json_response)
          |> Map.get("data")
          |> Enum.map(&KlineEvent.new/1)

        {:ok, candles}

      error ->
        error
    end
  end

  def build_get_candles(base_currency, quote_currency) do
    url = @endpoint <> "?instId=#{blessed_symbol(base_currency, quote_currency)}&bar=1m"

    Finch.build(:get, url)
  end

  def blessed_symbol(b, q) do
    String.upcase(b) <> "-" <> String.upcase(q)
  end
end
