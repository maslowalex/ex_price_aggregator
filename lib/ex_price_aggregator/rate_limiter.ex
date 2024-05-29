defmodule ExPriceAggregator.RateLimiter do
  @moduledoc """
  Requests pool and rate-limiter for public Okex exchange API
  """

  use GenServer

  defmodule State do
    defstruct tokens: 20, window: :timer.seconds(2), timer_ref: nil
  end

  def start_link(opts \\ []) do
    tokens = Keyword.fetch!(opts, :tokens)
    window = Keyword.fetch!(opts, :window)
    name = Keyword.fetch!(opts, :name)

    GenServer.start_link(__MODULE__, %State{tokens: tokens, window: window}, name: name)
  end

  def request(name, request, handler_module, function) do
    GenServer.call(name, {:request, request, handler_module, function})
  end

  def init(%State{} = state) do
    {:ok, state}
  end

  def handle_call({:request, _request, _hm, _fn}, _from, %{tokens: 0} = state) do
    {:reply, {:error, :rate_limited}, state}
  end

  def handle_call({:request, request, hm, fun}, _from, state) do
    tokens_left = calculate_tokens_left(request, state)

    case tokens_left do
      {:deny, _} ->
        {:reply, {:error, :rate_limited}, state}

      {:allow, tokens_left} ->
        timer_ref = maybe_set_timer_ref(state)
        response = apply(hm, fun, [request])

        {:reply, response, %State{state | tokens: tokens_left, timer_ref: timer_ref}}
    end
  end

  def handle_info(:reset_window, state) do
    {:noreply, %State{state | tokens: 20, timer_ref: nil}}
  end

  defp maybe_set_timer_ref(state) do
    case state.timer_ref do
      nil ->
        timer_ref = Process.send_after(self(), :reset_window, state.window)

        %State{state | timer_ref: timer_ref}

      _ ->
        state
    end
  end

  defp calculate_tokens_left(request, state) do
    tokens_left = state.tokens - request.private.weight * request.private.num_of_requests

    if tokens_left < 0 do
      {:deny, 0}
    else
      {:allow, tokens_left}
    end
  end
end
