defmodule ExPriceAggregator.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {
        Phoenix.PubSub,
        name: ExPriceAggregator.PubSub, adapter_name: Phoenix.PubSub.PG2
      },
      {DynamicSupervisor, strategy: :one_for_one, name: ExPriceAggregator.DynamicSupervisor},
      {Registry, [keys: :unique, name: ExPriceAggregator.ExchangeRegistry]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ExPriceAggregator.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
