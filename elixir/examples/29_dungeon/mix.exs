defmodule Ex29Dungeon.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex29_dungeon,
      version: "0.1.0",
      elixir: "~> 1.17",
      deps: []
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end
end
