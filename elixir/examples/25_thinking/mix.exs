defmodule Ex25Thinking.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex25_thinking,
      version: "0.1.0",
      elixir: "~> 1.17",
      deps: []
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end
end
