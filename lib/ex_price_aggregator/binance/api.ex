defmodule ExPriceAggregator.Binance.API do
  alias ExPriceAggregator.Binance.KlineEvent

  def get_candles(base_currency, quote_currency, opts) do
    build_get_candles(base_currency, quote_currency, opts)
    |> Finch.request(ExPriceAggregator.Finch)
    |> handle_response()
  end

  def build_get_candles(base_currency, quote_currency, opts \\ []) do
    timeframe = Keyword.fetch!(opts, :timeframe)
    limit = Keyword.fetch!(opts, :limit)
    url = url(:candles, blessed_symbol(base_currency, quote_currency), timeframe, limit)

    Finch.build(:get, url)
  end

  def blessed_symbol(b, q) do
    String.upcase(b) <> String.upcase(q)
  end

  @klines_endpoint "https://api.binance.com/api/v3/klines"

  def url(:candles, symbol, timeframe, limit) do
    query_params =
      Keyword.new()
      |> Keyword.put(:interval, timeframe)
      |> Keyword.put(:symbol, symbol)
      |> Keyword.put(:limit, limit)

    @klines_endpoint
    |> URI.new!()
    |> URI.append_query(URI.encode_query(query_params))
    |> URI.to_string()
  end

  def handle_response({:ok, %Finch.Response{status: 200, body: json_response}}) do
    candles =
      json_response
      |> Jason.decode!()
      |> Enum.map(&KlineEvent.new/1)
      |> Enum.map(&KlineEvent.to_generic/1)

    {:ok, candles}
  end

  def handle_response(error), do: error
end
