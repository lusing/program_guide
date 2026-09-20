defmodule Ex22MixRelease do
  @moduledoc """
  第 22 章示例：Mix 与 release。

  本工程同时承担三种打包形态的演示：普通 mix 工程（自定义任务、三层配置）、
  escript（单文件可执行，见 `CLI`）、release（自包含发布，见 run.exs 第 4 节）。
  """

  @doc """
  当前应用名。

      iex> Ex22MixRelease.app_name()
      :ex22_mix_release

  """
  @spec app_name() :: atom()
  def app_name do
    Mix.Project.config()[:app]
  end

  @doc """
  当前版本号（来自 mix.exs，固定字符串）。

      iex> Ex22MixRelease.app_version()
      "0.1.0"

  """
  @spec app_version() :: String.t()
  def app_version do
    Mix.Project.config()[:version]
  end

  @doc """
  读取选定的应用配置（编译期 + runtime.exs 的运行期项）。
  输出固定四元组，顺序写死，避免环境中其它注入键干扰。
  """
  @spec settings() :: [{atom(), String.t() | nil}]
  def settings do
    for key <- [:greeting, :env_tag, :boot_tag, :who] do
      {key, Application.get_env(:ex22_mix_release, key)}
    end
  end

  @doc "release eval 入口：打印固定一行即成功。"
  @spec hello() :: :ok
  def hello do
    IO.puts("release eval 运行成功")
  end
end

defmodule Ex22MixRelease.CLI do
  @moduledoc "escript 入口模块（mix.exs 的 escript: main_module 指向这里）。"

  @doc "escript 参数是 charlist 列表；我们不解析，固定打印。"
  @spec main([charlist()]) :: :ok
  def main(_argv) do
    IO.puts("escript 运行成功")
  end
end
