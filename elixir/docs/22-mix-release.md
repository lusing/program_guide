# 22 · Mix 与 release

> 对应示例：`examples/22_mix_release/`（独立 mix 工程，含 ExUnit 测试、doctest、`config/` 配置与 `run.exs` 驱动脚本）

到本章为止，Mix 一直是背景：`mix compile`、`mix test`、`mix run`。本章把
这套构建工具摆到台前，并实际产出三种形态的东西：**自包含 release**、
**单文件 escript**、**umbrella 伞形工程**。全部在临时目录里构建、运行、
删除，零依赖、不联网。

Mix 工程的核心只有一个文件：`mix.exs`。它定义工程的全部事实：

```elixir
defmodule Ex22MixRelease.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex22_mix_release,
      version: "0.1.0",
      elixir: "~> 1.17",
      deps: [],
      escript: [main_module: Ex22MixRelease.CLI, path: System.get_env("EX22_ES_PATH")]
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end
end
```

## 22.1 工程元数据：mix.exs 是唯一事实源

`Mix.Project.config/0` 在任何 Mix 会话里都能取到这个 keyword，应用代码也
能读——本章的 `app_name/0`、`app_version/0` 就是薄封装（带 doctest）：

```elixir
def app_name, do: Mix.Project.config()[:app]
def app_version, do: Mix.Project.config()[:version]
```

依赖写在 `:deps` 里（本教程全部为 `[]`；有依赖时形如
`{:jason, "~> 1.4"}`，Mix 默认从 hex.pm 拉取并存到 `deps/`，构建产物则
全部进 `_build/`——这两个目录都不提交）。

```text
-- 1. mix.exs 是工程的唯一事实源 --
  app => ex22_mix_release
  version => 0.1.0
  mix_env => dev
  deps => []
```

版本号要用 `MAJOR.MINOR.PATCH` 的字符串。加依赖后常用命令：`mix deps.get`
拉取、`mix deps.compile` 编译、`mix deps.tree` 看依赖树。

## 22.2 自定义 Mix 任务

在 `lib/mix/tasks/` 下放一个模块，它就自动成为同名 Mix 任务：
`lib/mix/tasks/who.ex` → `mix who`。

```elixir
defmodule Mix.Tasks.Who do
  use Mix.Task

  @shortdoc "打印自定义任务标签"

  @impl Mix.Task
  def run(_args) do
    IO.puts("mix who => 自定义任务运行（版本 #{Ex22MixRelease.app_version()}）")
  end
end
```

要点：

- 任务名即模块名去掉 `Mix.Tasks.`，snake_case；多词用
  `Mix.Tasks.Foo.Bar` → `mix foo.bar`。
- `run/1` 接收命令行参数的字符串列表；`@shortdoc` 让它出现在 `mix help`。
- 在代码中触发任务用 `Mix.Task.run/2`；同一任务已执行过不会重跑，
  强制重跑用 `Mix.Task.rerun/2`（本章脚本就靠它演示）。

```text
-- 2. lib/mix/tasks/ 下的模块自动成为 mix 任务 --
mix who => 自定义任务运行（版本 0.1.0）
```

## 22.3 三层配置：config.exs / 环境文件 / runtime.exs

Elixir 把配置按**求值时机**分成三层，是本章最值得建立的心智模型：

```text
config/config.exs  ── 构建期求值，固化进应用环境（release 打完不再变）
  ├─ dev.exs/test.exs/prod.exs ── 按 MIX_ENV 择一导入
config/runtime.exs ── 每次启动时求值；可读环境变量，同一 release 不同机器取不同值
```

```elixir
# config/config.exs
import Config
config :ex22_mix_release, greeting: "编译期配置"
import_config "#{config_env()}.exs"          # => "dev.exs" / "test.exs" / "prod.exs"

# config/runtime.exs
import Config
config :ex22_mix_release,
  who: System.get_env("DEMO_WHO", "世界"),  # 部署时给环境变量即可改变
  boot_tag: "runtime 配置"
```

三层最终都汇进 `Application.get_env(:app, key)`。本章 `settings/0` 固定
挑四个键、固定顺序打印：

```text
-- 3. 编译期 + 环境 + 运行期三类配置在 Application env 汇合 --
  greeting => 编译期配置
  env_tag => dev 环境
  boot_tag => runtime 配置
  who => 世界
```

选型规则：**随包走、所有环境一致**的放 config.exs；**随部署环境变**的放
runtime.exs（数据库地址、端口、密钥）。一个反模式是在 runtime.exs 里写死
所有东西——配置虽集中了，但「构建期可检查」的好处全丢了。

注意环境名：`MIX_ENV` 选 `dev`/`test`/`prod`；`mix test` 默认自动用
`test`，但**显式设置的 MIX_ENV 会保留**。本教程的 run-all 统一导出
`MIX_ENV=dev` 跑全部五层，所以本节标签是 `dev 环境`（测试里的期望值也按
`Mix.env()` 动态取）。

## 22.4 mix release：自包含发布

`MIX_ENV=prod mix release` 把应用、依赖、**整套 BEAM 运行时**打进一个
目录，目标机器不需要装 Elixir/Erlang——这是 Elixir 的标准部署形态。
本章脚本把发布指到临时目录：

```elixir
Ex22MixRelease.Steps.run!(
  "mix",
  ["release", "--quiet", "--overwrite", "--path", rel_path],
  cd: project_dir
)
```

发布目录里的 `bin/<app>` 是操作入口，常用方式：

| 命令 | 行为 |
|---|---|
| `bin/app start` / `stop` | 后台启动常驻系统 / 停止 |
| `bin/app foreground` | 前台运行（看输出） |
| `bin/app eval "代码"` | 启动运行时执行一段代码后退出（本章用它） |
| `bin/app rpc "Mod.fun()"` | 对已运行的节点远程调用 |
| `bin/app daemon_*` | 配合 pid 文件的守护化 |

```text
-- 4. release 含整个 BEAM 与应用；eval 不常驻，跑完即退 --
  release eval 运行成功
```

要点：release 是 prod-only 概念；常驻应用需要在 `application/0` 定义
`mod: {AppModule, args}`（即第 16 章的 Application 回调），否则 `start`
没有可启动的树。版本升级（`bin/app upgrade`）、tar 包（`mix release --tar`）
是进一步的运维话题。

## 22.5 escript：单文件可执行

`mix escript.build` 把全部字节码打成**一个**可执行文件，适合在开发者
之间分发小工具：

```elixir
Ex22MixRelease.Steps.run!(
  "mix",
  ["escript.build", "--quiet"],
  cd: project_dir,
  env: [{"EX22_ES_PATH", es_path}]
)
```

入口在 `mix.exs` 的 `escript: [main_module: ...]` 指定，模块提供
`main/1`：

```elixir
defmodule Ex22MixRelease.CLI do
  def main(_argv) do
    IO.puts("escript 运行成功")
  end
end
```

```text
-- 5. escript 打成一个可执行文件 --
  escript 运行成功
```

三个实测细节：

- escript **只需要目标机有 Erlang/OTP**——Elixir 本身被嵌进文件；但它
  不是部署机制，跑常驻系统请用 release。
- **输出路径只能在 mix.exs 的 `:path` 配置**，命令行没有 `--path`
  选项（误用会被静默忽略，escript 以 app 名落在当前目录）。本章让
  mix.exs 读环境变量 `EX22_ES_PATH`，从而把产物指到临时目录。
- **运行产物的方式分平台**：Unix 靠 shebang 直接执行产物本身；Windows
  上产物无扩展名、不是 PE 可执行文件，直接 spawn 报 `:eacces`，必须经
  `escript` 命令（escript.exe）运行——`System.cmd("escript", [path])`。
  顺带一提：`System.cmd("mix", ...)` 与 release 的 `bin/app` 在 Windows
  上能被自动解析到 `mix.bat` / `bin/app.bat`，无需特殊处理（实测）。

## 22.6 umbrella：伞形工程

一个根工程 + `apps/` 下多个独立子应用，是 Elixir 的 monorepo 形态。
根 `mix.exs` 只有一行关键配置，不产任何代码：

```elixir
defmodule Umb.MixProject do
  use Mix.Project

  def project do
    [apps_path: "apps"]
  end
end
```

本章在临时目录手工造 `core`、`web` 两个子应用，`mix compile --quiet`
后可以直接跨应用调用（Mix 在伞根运行时会加载全部子应用）：

```text
-- 6. umbrella 根工程不产代码，只聚合 apps/ 下的子应用 --
  umbrella: core + web
```

伞形工程里：

- 每个子应用都是**完整 mix 工程**，可独立编译测试（`mix cmd --app core mix test`），
  互相间用 `in_umbrella: "core"` 声明依赖，内部调用就是普通的模块调用。
- 子应用间仍通过明确的 API 边界通信——拆成 umbrella 不等于可以随便耦合；
  只为「需要一起版本化、一起部署，但边界清晰」的一组应用而选。

## 22.7 MIX_ENV：prod 环境整体切换

最后验证环境切换：`MIX_ENV=prod` 时导入的是 `prod.exs`、编译走
`_build/prod`，与 dev 完全隔离。脚本里先做一次「构建步骤」
（`mix compile --quiet`，输出含路径、直接丢弃），再用
`--no-compile` 运行——这样两次执行的输出逐字节一致：

```elixir
Ex22MixRelease.Steps.run!(
  "mix", ["compile", "--quiet"],
  cd: project_dir, env: [{"MIX_ENV", "prod"}]
)

out =
  Ex22MixRelease.Steps.run!(
    "mix",
    ["run", "--no-start", "--no-compile", "-e",
     "IO.puts(\"env=prod tag=\" <> Application.fetch_env!(:ex22_mix_release, :env_tag))"],
    cd: project_dir, env: [{"MIX_ENV", "prod"}]
  )
```

```text
-- 7. MIX_ENV=prod 时导入的是 prod.exs，配置与编译整体切换 --
  env=prod tag=prod 环境
  临时工作区已清理
```

`mix run` 本身没有 `--quiet` 选项；第一次编译打印的
「Compiling…/Generated…」在第二次（已编译）不会出现——所以「先把编译
作为独立构建步骤、再 `--no-compile` 运行」是让脚本输出稳定的通用技巧。

## 22.8 要点小结

```text
  mix.exs 是唯一事实源；依赖在 deps，产物在 _build/，均不提交
  MIX_ENV 三环境：dev/test/prod；显式 MIX_ENV 会被尊重（mix test 不强制改）
  三层配置：config.exs 构建期、env 文件按环境、runtime.exs 启动期读环境变量
  lib/mix/tasks/ 自动注册任务；Mix.Task.rerun/2 可强制重跑
  release = 含 BEAM 的自包含发布（prod-only），eval 一次性、start 常驻
  escript = 单文件（目标机需 Erlang），路径只在 mix.exs 配
  umbrella 用 apps_path 聚合边界清晰的子应用
```

## 22.9 坑位清单

1. **`mix escript.build` 没有 `--path`**：路径只能写在 mix.exs 的
   `escript: [path: ...]`，未知 CLI 参数会被静默忽略，escript 以 app 名
   落在当前目录。需要动态路径就读环境变量（本章做法）。
2. **`mix run` 没有 `--quiet`**。要稳定输出：先把 `mix compile` 当独立
   构建步骤（输出丢弃），再 `mix run --no-compile`——否则首次编译的
   「Compiling…」只在一次执行里出现，双层比对必挂。
3. **MIX_ENV 显式设置后不会被自动覆盖**。`mix test` 默认用 test，但
   环境里有 `MIX_ENV=dev` 就按 dev 编译加载；测试断言别写死环境名，
   按 `Mix.env()` 取期望值。
4. **构建产物分环境隔离**：`_build/dev`、`_build/test`、`_build/prod`
   各一套 beam；「dev 下好好的，prod 崩了」往往就是两套编译差异，排查时
   显式带 MIX_ENV 重跑。
5. **runtime.exs 会被打进 release/escript**：里面可以读环境变量，但也会
   在构建工具的各种任务下被求值——别在顶层做有副作用、会失败的事；缺
   变量要给默认值，否则 `mix compile` 都可能受影响。
6. **release 的 `start` 需要 Application 回调**（第 16 章的 `mod:`）。
   没有常驻树的工程只能 `eval`/`rpc`；首次打 release 先想清楚「启动的是
   哪棵监督树」。
7. **escript 不是 release 的替代品**：面向开发者分发工具用 escript（机器
   要有 Erlang），面向生产部署用 release（机器什么都不用装）。
8. **umbrella 不是「随便互调」许可证**：子应用间要显式声明
   `in_umbrella` 依赖、走公开 API；apps/ 只是物理聚合，边界纪律照旧。
9. **子进程输出含绝对路径与构建日志**：脚本里统一捕获、只打印自选行；
   任何来自 `mix build` 的原始输出都会破坏第 5 层逐字节比对。
10. **离线/零依赖纪律下别引入需要 rebar3 或 hex 的东西**：NIF、git 依赖
    都会触发额外工具链；本章所有产物（release/escript/umbrella）只用
    Mix 内建能力手工生成。
11. **Windows 上运行 escript 产物要走 escript 命令**：产物无扩展名、不是
    PE 可执行文件，直接 spawn 报 `:eacces`；`System.cmd("escript", [path])`
    即可。`System.cmd("mix", ...)` 与 release 的 `bin/app` 会被 Windows
    自动解析到 `mix.bat` / `bin/app.bat`，无需特殊处理（实测）。

---

下一章回到语言本身的最后一块基石：[23 · 宏与元编程 / 类型检查](23-macros-types.md)
——`quote`/`unquote` 看代码即数据、宏的卫生性、`use` 与 `__using__` 回调，
以及 `@spec`/`@type` 和 Elixir 1.20 新类型检查器能在编译期抓住什么。
