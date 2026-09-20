# 第 22 章驱动脚本：cd examples/22_mix_release && mix run --no-compile run.exs
:io.setopts(:standard_io, encoding: :utf8)

alias Ex22MixRelease

project_dir = File.cwd!()

# 临时工作区：release/escript/umbrella 全部产在里面，结尾删干净；不打印路径。
workspace = Path.join(System.tmp_dir!(), "ex22_#{System.unique_integer([:positive])}")
File.mkdir_p!(workspace)

defmodule Ex22MixRelease.Steps do
  @moduledoc false

  # 统一执行外部命令：stderr 合并进捕获（mix 编译信息含路径，全部不外放），
  # 只把「运行类」命令的 stdout 交给调用方选择性打印。
  def run!(cmd, args, opts \\ []) do
    case System.cmd(cmd, args, [stderr_to_stdout: true] ++ opts) do
      {out, 0} ->
        out

      {out, code} ->
        IO.puts("命令失败 code=#{code}: #{cmd} #{Enum.join(args, " ")}")
        IO.write(out)
        System.halt(1)
    end
  end
end

IO.puts("==== 22 Mix 与 release：元数据、自定义任务、三层配置、release、escript、umbrella、环境 ====")

# ------------------------------------------------------------
# 1. 工程元数据
# ------------------------------------------------------------
IO.puts("\n-- 1. mix.exs 是工程的唯一事实源 --")
IO.puts("  app => #{Ex22MixRelease.app_name()}")
IO.puts("  version => #{Ex22MixRelease.app_version()}")
IO.puts("  mix_env => #{Mix.env()}")
IO.puts("  deps => #{inspect(Keyword.keys(Mix.Project.config()[:deps]))}")

# ------------------------------------------------------------
# 2. 自定义 Mix 任务（lib/mix/tasks/who.ex）
# ------------------------------------------------------------
IO.puts("\n-- 2. lib/mix/tasks/ 下的模块自动成为 mix 任务 --")
Mix.Task.rerun("who", [])

# ------------------------------------------------------------
# 3. 三层配置：config.exs / 环境文件 / runtime.exs
# ------------------------------------------------------------
IO.puts("\n-- 3. 编译期 + 环境 + 运行期三类配置在 Application env 汇合 --")

Enum.each(Ex22MixRelease.settings(), fn {k, v} ->
  IO.puts("  #{k} => #{v}")
end)

# ------------------------------------------------------------
# 4. mix release：打自包含发布，再用 eval 跑函数
# ------------------------------------------------------------
IO.puts("\n-- 4. release 含整个 BEAM 与应用；eval 不常驻，跑完即退 --")
rel_path = Path.join(workspace, "rel")

Ex22MixRelease.Steps.run!(
  "mix",
  [
    "release",
    "--quiet",
    "--overwrite",
    "--path",
    rel_path
  ],
  cd: project_dir
)

out =
  Ex22MixRelease.Steps.run!(
    Path.join(rel_path, "bin/ex22_mix_release"),
    ["eval", "Ex22MixRelease.hello()"]
  )

IO.write("  #{out}")

# ------------------------------------------------------------
# 5. escript：单文件可执行（内含 BEAM 字节码，目标机需有 Erlang）
# ------------------------------------------------------------
IO.puts("-- 5. escript 打成一个可执行文件 --")
es_path = Path.join(workspace, "ex22")

Ex22MixRelease.Steps.run!(
  "mix",
  ["escript.build", "--quiet"],
  cd: project_dir,
  env: [{"EX22_ES_PATH", es_path}]
)

out = Ex22MixRelease.Steps.run!(es_path, [])
IO.write("  #{out}")

# ------------------------------------------------------------
# 6. umbrella：手工造一个两子应用伞形工程，编译并跨应用调用
# ------------------------------------------------------------
IO.puts("-- 6. umbrella 根工程不产代码，只聚合 apps/ 下的子应用 --")
umb = Path.join(workspace, "umb")

umb_files = %{
  "mix.exs" => """
  defmodule Umb.MixProject do
    use Mix.Project

    def project do
      [apps_path: "apps"]
    end
  end
  """,
  "apps/core/mix.exs" => """
  defmodule Core.MixProject do
    use Mix.Project

    def project do
      [app: :core, version: "0.1.0"]
    end

    def application do
      [extra_applications: []]
    end
  end
  """,
  "apps/core/lib/core.ex" => """
  defmodule Core do
    def hello, do: "core"
  end
  """,
  "apps/web/mix.exs" => """
  defmodule Web.MixProject do
    use Mix.Project

    def project do
      [app: :web, version: "0.1.0"]
    end

    def application do
      [extra_applications: []]
    end
  end
  """,
  "apps/web/lib/web.ex" => """
  defmodule Web do
    def name, do: "web"
  end
  """
}

Enum.each(umb_files, fn {rel, content} ->
  path = Path.join(umb, rel)
  File.mkdir_p!(Path.dirname(path))
  File.write!(path, content)
end)

Ex22MixRelease.Steps.run!("mix", ["compile", "--quiet"], cd: umb)

out =
  Ex22MixRelease.Steps.run!(
    "mix",
    [
      "run",
      "--no-start",
      "-e",
      "IO.puts(\"umbrella: \" <> Core.hello() <> \" + \" <> Web.name())"
    ],
    cd: umb
  )

IO.write("  #{out}")

# ------------------------------------------------------------
# 7. MIX_ENV：prod 环境重跑，配置整体切换
# ------------------------------------------------------------
IO.puts("-- 7. MIX_ENV=prod 时导入的是 prod.exs，配置与编译整体切换 --")

# 先把 prod 构建作为「构建步骤」（输出含路径，丢弃）；这样 run 在两层里
# 都不必再编译，可用 --no-compile 得到完全一致的输出（run 本身没有 --quiet）。
Ex22MixRelease.Steps.run!(
  "mix",
  ["compile", "--quiet"],
  cd: project_dir,
  env: [{"MIX_ENV", "prod"}]
)

out =
  Ex22MixRelease.Steps.run!(
    "mix",
    [
      "run",
      "--no-start",
      "--no-compile",
      "-e",
      "IO.puts(\"env=prod tag=\" <> Application.fetch_env!(:ex22_mix_release, :env_tag))"
    ],
    cd: project_dir,
    env: [{"MIX_ENV", "prod"}]
  )

IO.write("  #{out}")

File.rm_rf!(workspace)
IO.puts("  临时工作区已清理")

IO.puts("""
-- Mix 要点 --
  mix.exs 是唯一事实源；MIX_ENV 切三套环境（dev/test/prod），配置文件分别导入
  config.exs 构建期固化；runtime.exs 启动时求值、可读环境变量
  lib/mix/tasks/ 下的模块自动注册为 mix 任务
  mix release 出自包含发布（含 BEAM），eval 跑一次性逻辑，start/stop 管常驻
  escript 出单文件可执行；umbrella 用 apps_path 聚合多个子应用
  构建产物全部进 _build/，不提交；脚本演示放临时目录、结尾清理
""")

IO.puts("==== 22 结束 ====")
