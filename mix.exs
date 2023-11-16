defmodule ExPriceAggregator.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_price_aggregator,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ExPriceAggregator.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:websockex, "~> 0.4.3"},
      {:phoenix_pubsub, "~> 2.0"},
      {:jason, "~> 1.2"},
      {:stream_gzip, "~> 0.4"},
      {:decimal, "~> 2.1"}
    ]
  end
end
