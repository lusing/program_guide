# Elixir 教程（Elixir 1.20.2/1.20.4 · OTP 29）

函数式 · 不可变数据 ·  actor 进程与监督树——从零教到能写容错并发应用的程度。
定位：**会编程（C++/Python 背景最佳）、初学 Elixir**；所有示例在 macOS
（Elixir 1.20.2）与 Windows/scoop（Elixir 1.20.4）双轨实测通过，均为
OTP 29。**零外部依赖、可离线验证**，主线只用标准库
（GenServer/Task/Supervisor/Logger/ExUnit…）。

## 目录结构

```text
elixir/
  docs/          29 章正文（01 全景 → 29 领域建模收官）
  examples/      28 个独立 mix 工程（章号 = 目录号；01 为纯文档章）
  build.ps1      验证脚本（pwsh；-All / -Example NN_topic / -Clean）
  run-all.sh     bash 版双入口
  CHEATSheet.md  语法速查 + 42 条实测坑位索引
```

每个示例工程的最小形态：

```text
NN_topic/
├── mix.exs                 工程单一事实源（app、elixir 版本、deps、application）
├── .formatter.exs          2 空格格式配置
├── lib/
│   └── exNN_topic.ex       库模块：@moduledoc/@doc 内嵌 doctest + @spec
├── run.exs                 驱动脚本：分节演示，末尾打印「==== NN 结束 ====」
└── test/
    ├── test_helper.exs     ExUnit.start()
    └── exNN_topic_test.exs doctest + 多个 test
```

部分章（16、22、24、29）因需要 Application/release/监督树/多模块领域
模型，在 `lib/` 下另有拆分模块与 `config/` 配置层。

## 章节索引

| # | 主题 |
|---|---|
| 01 | [全景：BEAM 三支柱、let-it-crash、安装与 mix 初识](docs/01-overview.md)（纯文档） |
| 02 | [第一个程序：四种运行形态、mix 工程解剖、编码坑](docs/02-hello.md) |
| 03 | [基础类型与不可变性：数字/原子/真假/全序](docs/03-types.md) |
| 04 | [模式匹配：绑定、解构、`^` pin、map/二进制匹配](docs/04-pattern-matching.md) |
| 05 | [函数与递归：多子句、守卫、默认参数、尾递归 TCO](docs/05-functions-recursion.md) |
| 06 | [控制流：case/cond/if/with、作用域与变量泄漏](docs/06-control-flow.md) |
| 07 | [Enum 与管道：reduce、手写 map/filter、`\|>`、排序、推导式](docs/07-enum.md) |
| 08 | [字符串与 Unicode：字节/码点/字素、emoji 与组合字符](docs/08-strings-unicode.md) |
| 09 | [集合：Keyword / Map / Struct / MapSet、Access](docs/09-collections.md) |
| 10 | [协议与行为：defprotocol/defimpl、derive、@behaviour](docs/10-protocols.md) |
| 11 | [错误处理与日志：tagged tuple、try/rescue、raise/throw/exit、Logger](docs/11-errors.md) |
| 12 | [进程与消息：spawn/send/receive、link/monitor、命名进程、状态 loop](docs/12-processes.md) |
| 13 | [Task 并发：async/await、async_stream、超时、失败传播](docs/13-task.md) |
| 14 | [Agent 状态：get/update/get_and_update、适用边界](docs/14-agent.md) |
| 15 | [GenServer：API+回调、call/cast/info、超时、通用服务器模式](docs/15-genserver.md) |
| 16 | [Supervisor 与 Application：监督策略、child_spec、重启阈值](docs/16-supervision.md) |
| 17 | [正则与二进制模式：捕获、位串 size/unit、手写二进制帧](docs/17-regex-binaries.md) |
| 18 | [Stream 惰性流：resource/iterate/cycle、chunk、无限流、恒定内存](docs/18-streams.md) |
| 19 | [文件与 IO：File、行流、Path、iodata、目录、:file](docs/19-files.md) |
| 20 | [日期与时间：四类结构、日历算术、Unix 互转、时区坑](docs/20-dates.md) |
| 21 | [测试 ExUnit：describe/setup、doctest、capture_io/log、不 mock](docs/21-testing.md) |
| 22 | [Mix 与 release：三层配置、自定义任务、release、escript、umbrella](docs/22-mix-release.md) |
| 23 | [宏与元编程 / 类型检查：quote/unquote、卫生性、use、@type/@spec](docs/23-macros-types.md) |
| 24 | [收官项目：容错缓存 + 并发词频（杀 worker 重试、杀服务自愈）](docs/24-capstone.md) |
| 25 | [函数式思维：不可变与结构共享、纯函数、声明式（书 ch1）](docs/25-functional-thinking.md) |
| 26 | [闭包与函数组合：捕获定值、遮蔽、`&` 全形态、compose](docs/26-closures.md) |
| 27 | [递归进阶：减治/分治、归并排序、无界护栏、自递归](docs/27-recursion-deep.md) |
| 28 | [纯函数纪律与错误单子：case/rescue/throw/单子/with 五策略](docs/28-purity-monad.md) |
| 29 | [领域建模：回合制地下城（struct+协议+行为+typespec）](docs/29-dungeon.md) |

## 怎么跑

```bash
cd examples/24_capstone
mix deps.get          # 本教程无需执行：deps 均为空
mix compile           # 编译
mix test              # 跑 ExUnit（含 doctest）
mix format            # 格式化
mix run run.exs       # 跑分节演示
```

## 验证

```bash
./run-all.sh                  # 全量：28 个工程 × 五层
./run-all.sh 24_capstone      # 单个示例
./run-all.sh --clean          # 清理 build/
pwsh ./build.ps1 -All         # PowerShell 等价入口
```

五层判定：

1. `mix format --check-formatted` 格式干净；
2. `mix compile --warnings-as-errors --force` 编译零告警；
3. `mix test` ExUnit 全绿；
4. `mix run --no-compile run.exs`：退出码 0、stderr 空、stdout 非空、
   含结束标记 `==== NN 结束 ====`；
5. `ERL_FLAGS="+S 1:1"`（单调度器）重跑，stdout 与第 4 层**逐字节一致**。

例外：`11_errors` 故意往 stderr 写异常与日志（run-all.sh 的 `STDERR_ALLOW`）。
第 5 层是本教程确定性纪律的技术保障：示例只断言性质、排序后输出，
不打印 pid/时间戳/路径等环境相关内容。

Windows 注意：`mix format` 只认 LF——本目录自带 `.gitattributes` 强制
`eol=lf`，防止 git `core.autocrlf=true` 把检出文件变 CRLF 令第 1 层全挂
（见 CHEATSheet 坑位 33–35 的三条 Windows 实测坑）。

## 相关教程

同仓库：[haskell](../haskell/)、[julia](../julia/)、[clojure](../clojure/)、
[erlang](../erlang/)、[rust](../rust/) 等（同一结构标准：分章文档 +
章号=示例号 + 坑位清单 + 多层验证）。
