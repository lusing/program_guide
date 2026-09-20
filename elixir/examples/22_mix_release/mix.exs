defmodule Ex22MixRelease.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex22_mix_release,
      version: "0.1.0",
      elixir: "~> 1.17",
      deps: [],
      # escript 输出路径只能在这里配（CLI 无 --path）；演示脚本通过环境变量
      # 把它指到临时目录，未设置时为 nil => 默认落在工程根（app 同名）。
      escript: [main_module: Ex22MixRelease.CLI, path: System.get_env("EX22_ES_PATH")]
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end
end
