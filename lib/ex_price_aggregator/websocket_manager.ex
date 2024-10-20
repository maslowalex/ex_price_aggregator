defmodule ExPriceAggregator.WebsocketManager do
  @moduledoc """
  This module is managing websocket connections per instrument and exchange.
  Used for multiplexing websocket connections.

  Whenever a new instrument is added to the system, a new websocket connection is spawned.
  It could be a trade or a candle feed.
  """

  defmodule State do
    @moduledoc false

    defstruct [:pid, :timeframes, :child_spec, :flush_ref]
  end

  require Logger

  use GenServer

  def start_link(opts \\ []) do
    exchange = Keyword.fetch!(opts, :exchange)
    symbol = Keyword.fetch!(opts, :symbol)

    GenServer.start_link(__MODULE__, opts, name: name(exchange, symbol))
  end

  def init(opts) do
    child_spec = Keyword.fetch!(opts, :child_spec)
    tf = Keyword.fetch!(opts, :timeframe)
    exchange = Keyword.fetch!(opts, :exchange)
    symbol = Keyword.fetch!(opts, :symbol)

    {:ok, %State{timeframes: [tf], child_spec: child_spec}, {:continue, :init_ws_conn}}
  end

  def handle_continue(:init_ws_conn, state) do
    pid =
      case DynamicSupervisor.start_child(ExPriceAggregator.DynamicSupervisor, state.child_spec) do
        {:ok, pid} -> pid
        {:error, {_, pid}} -> pid
      end

    Process.monitor(pid)

    {:noreply, %State{state | pid: pid}}
  end

  def subscribe(exchange, symbol, tf) do
    exchange
    |> name(symbol)
    |> GenServer.call({:subscribe, tf}, :infinity)
  end

  def handle_call({:subscribe, tf}, _from, state) do
    timeframes =
      state.timeframes
      |> MapSet.new()
      |> MapSet.put(tf)
      |> MapSet.to_list()

    flush_ref = maybe_flush_ref(state.flush_ref)

    {:reply, :ok, %State{state | timeframes: timeframes, flush_ref: flush_ref}}
  end

  def handle_info(:flush, %State{timeframes: []} = state) do
    {:noreply, state}
  end

  def handle_info(:flush, %State{timeframes: timeframes, pid: ws_pid} = state) do
    send(ws_pid, {:subscribe, timeframes})

    {:noreply, %State{state | flush_ref: nil}}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, %State{pid: pid} = state) do
    Logger.warning("Websocket connection for #{inspect(pid)} is down, restarting...")

    pid =
      case DynamicSupervisor.start_child(ExPriceAggregator.DynamicSupervisor, state.child_spec) do
        {:ok, pid} -> pid
        {:error, {_, pid}} -> pid
      end

    Process.send_after(self(), :flush, 5_000)

    {:noreply, %State{state | pid: pid}}
  end

  def handle_info(msg, state) do
    Logger.info("Received unknown message: #{inspect(msg)}, #{inspect(state)}")

    {:noreply, state}
  end

  def name(exchange, symbol) do
    :"ws_manager_#{exchange}_#{symbol}"
  end

  defp maybe_flush_ref(nil), do: Process.send_after(self(), :flush, 5_000)
  defp maybe_flush_ref(ref), do: ref
end
