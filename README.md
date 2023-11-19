# ExPriceAggregator

To subscribe to websocket feed of one of the 4 exchanges use:

```elixir
{:ok, pid} = ExPriceAggregator.track_trades(:okex, "btc", "usdt")

:ok = ExPriceAggregator.untrack_trades(:okex, "btc", "usdt")
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ex_price_aggregator` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_price_aggregator, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/ex_price_aggregator>.

