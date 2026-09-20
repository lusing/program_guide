defmodule Mix.Tasks.Who do
  @moduledoc "自定义 Mix 任务：mix who"
  use Mix.Task

  @shortdoc "打印自定义任务标签"

  @impl Mix.Task
  def run(_args) do
    IO.puts("mix who => 自定义任务运行（版本 #{Ex22MixRelease.app_version()}）")
  end
end
