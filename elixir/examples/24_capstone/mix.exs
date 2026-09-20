defmodule Ex24Capstone.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex24_capstone,
      version: "0.1.0",
      elixir: "~> 1.17",
      deps: []
    ]
  end

  def application do
    [
      mod: {Ex24Capstone.Application, []},
      extra_applications: [:logger]
    ]
  end
end
