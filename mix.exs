defmodule Dhcp.MixProject do
  use Mix.Project

  def project do
    [
      app: :dhcp,
      version: "0.1.0",
      elixir: "~> 1.12-dev",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Dhcp.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ra, "~> 1.1"},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:distillery, "~> 2.1"},
      {:dialyxir, "~> 1.0.0", only: [:dev], runtime: false},
      {:extrace, "~> 0.2.1"}
    ]
  end
end
