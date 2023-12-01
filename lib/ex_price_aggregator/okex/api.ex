defmodule ExPriceAggregator.Okex.API do
  alias ExPriceAggregator.Okex.KlineEvent

  @endpoint "https://www.okx.com/api/v5/market/history-candles"
  @api_batch_limit 100

  def get_candles(base_currency, quote_currency, opts) do
    num_of_requests = ceil(Keyword.get(opts, :limit, 100) / @api_batch_limit)

    build_get_candles(base_currency, quote_currency, opts)
    |> Finch.request(ExPriceAggregator.Finch)
    |> handle_response()
    |> case do
      {:ok, candles, latest_ts} ->
        opts = Keyword.put(opts, :after, latest_ts)
        get_candles(base_currency, quote_currency, opts, num_of_requests - 1, candles)

      error ->
        error
    end
  end

  def get_candles(_, _, _, 0, candles), do: {:ok, candles}

  def get_candles(base_currency, quote_currency, opts, num_of_requests, candles) do
    build_get_candles(base_currency, quote_currency, opts)
    |> Finch.request(ExPriceAggregator.Finch)
    |> handle_response()
    |> case do
      {:ok, new_candles, latest_ts} ->
        get_candles(
          base_currency,
          quote_currency,
          Keyword.put(opts, :after, latest_ts),
          num_of_requests - 1,
          candles ++ new_candles
        )

      error ->
        error
    end
  end

  def build_get_candles(base_currency, quote_currency, opts \\ []) do
    timeframe = Keyword.get(opts, :timeframe, :"1m")
    after_ts = Keyword.get(opts, :after, nil)
    url = url(base_currency, quote_currency, timeframe, after_ts)

    Finch.build(:get, url)
  end

  def blessed_symbol(b, q) do
    String.upcase(b) <> "-" <> String.upcase(q)
  end

  def url(base_currency, quote_currency, timeframe, after_ts \\ nil) do
    query_params =
      Keyword.new()
      |> Keyword.put(:bar, timeframe)
      |> Keyword.put(:instId, blessed_symbol(base_currency, quote_currency))
      |> maybe_put(:after, after_ts)

    @endpoint
    |> URI.new!()
    |> URI.append_query(URI.encode_query(query_params))
    |> URI.to_string()
  end

  def handle_response({:ok, %Finch.Response{status: 200, body: json_response}}) do
    candles =
      Jason.decode!(json_response)
      |> Map.fetch!("data")
      |> Enum.map(&KlineEvent.new/1)

    latest_ts = candles |> Enum.at(-1) |> Map.fetch!(:ts)

    {:ok, candles, latest_ts}
  end

  def handle_response(error), do: error

  defp maybe_put(kw, _, nil), do: kw
  defp maybe_put(kw, k, v), do: Keyword.put(kw, k, v)
end
