defmodule Ex19Files.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex19_files,
      version: "0.1.0",
      elixir: "~> 1.17",
      deps: []
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end
end
