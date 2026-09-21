# Prolog 教程（SWI-Prolog 10.0.2 / GNU Prolog 1.5.0）

逻辑编程 · 合一与回溯 · DCG 解析 · 约束求解 · 元编程 —— 从零教到能自己写解释器。
定位：**会编程（有任意一门语言基础即可）、初学 Prolog**。
所有示例在 macOS + SWI-Prolog 10.0.2 / GNU Prolog 1.5.0 实测通过，
**同一份源码在三条通道上输出逐字节一致**。

## 本教程的主张：两套引擎交叉验证

Prolog 有 ISO 标准（ISO/IEC 13211-1，1995），但两套主流实现各有取舍。
本教程**把每一章都在两套引擎上跑一遍并逐字节比对输出** ——
不是为了教你「迁就某个实现」，而是让你亲眼看到
**「哪些是语言本身，哪些只是某个实现的私货」**：

| | SWI-Prolog | GNU Prolog |
|---|---|---|
| 定位 | 库最全、社区最活跃，工程默认选择 | 体量极小，自带 FD 约束求解器，能编成无运行时依赖的本地二进制 |
| CLP(FD) | `library(clpfd)`（属性变量） | **内建** `fd_*`（独立类型） |
| 模块系统 | 完整（`module/2`、`use_module/2`、`模块:目标`） | **没有**，`module/2` 被静默忽略 |
| `consult/1` | 安静 | **往 stdout 打编译进度** |
| 浮点打印 | 最短表示（`3.14`） | 17 位（`3.1400000000000001`） |

正是这些差异，逼出了教程里那份「安全子集」（见 `CHEATSheet.md` 第 21 节）。

## 目录结构

```text
prolog/
  docs/          24 章正文（01 全景 → 24 综合项目）
  examples/      NN_topic/NN_topic.pl（02–24 共 23 个可运行示例）
                 + 部分章附 observe_*.pl（引擎差异观察文件，只要求跑到底）
  run-all.sh     三通道验证入口（bash）
  build.ps1      三通道验证入口（pwsh，判定与 run-all.sh 逐项一致）
  CHEATSheet.md  语法速查 + 226 条实测坑位索引
  build/         验证产物（可删；.gitignore 覆盖）
```

示例目录：

```text
02_hello/02_hello.pl                     CHATSheet 里的骨架就长这样
21_constraints/
  ├── 21_constraints.pl                  正文示例（只用可移植适配层）
  ├── observe_21_swi.pl                  只跑 SWI：原生 clpfd 能力
  └── observe_21_gnu.pl                  只跑 GNU：原生 fd_* 能力
22_modules/
  ├── 22_modules.pl                      正文示例
  ├── observe_22_swi.pl                  同一份带模块头的文件 → 内部谓词真被藏住
  └── observe_22_gnu.pl                  同一份文件 → 内部谓词照样可见
```

`observe_*.pl` 的命名约定：后缀 `_swi` 只在 SWI 跑、`_gnu` 只在 GNU 跑、
无后缀两边都跑；它们**不参与逐字节比对**，只要求「跑到底」。

## 章节索引

| # | 主题 |
|---|---|
| 01 | [全景：Prolog 是什么、两套引擎、三通道与六条判定](docs/01-overview.md)（纯文档） |
| 02 | [第一个程序：`main/0` 骨架、输出区间约定、编码坑](docs/02-hello.md) |
| 03 | [事实、规则与查询：数据库、递归规则、子句顺序](docs/03-facts-rules.md) |
| 04 | [项：原子/数字/变量/复合项、`functor/3`、标准项序](docs/04-terms.md) |
| 05 | [合一与同一性：`=` vs `==`、发生检查、`=..`](docs/05-unification.md) |
| 06 | [回溯与搜索树：选择点、生成-测试、搜索代价](docs/06-backtracking.md) |
| 07 | [算术与比较：`is` vs `=`、整除、浮点的跨引擎分歧](docs/07-arithmetic.md) |
| 08 | [列表：`[H\|T]`、`member/append`、手写集合运算](docs/08-lists.md) |
| 09 | [递归、累加器与尾调用：倒着攒再 `reverse`](docs/09-recursion.md) |
| 10 | [剪枝与否定：`!`、`->`、`\+`、绿切与红切](docs/10-cut.md) |
| 11 | [高阶谓词与元调用：`call/N`、闭包、`maplist`、`forall`](docs/11-higher-order.md) |
| 12 | [元编程：`functor/arg/=..`、类型判定、`copy_term`](docs/12-metaprogramming.md) |
| 13 | [解集收集：`findall` / `bagof` / `setof`、可移植聚合](docs/13-all-solutions.md) |
| 14 | [输入输出：流模型、写文件、项序列化](docs/14-io.md) |
| 15 | [文本处理：原子/码列表、`sub_atom/5`、中文为什么不能数](docs/15-text.md) |
| 16 | [运算符：`op/3`、优先级表、`write_canonical/1`](docs/16-operators.md) |
| 17 | [动态数据库：`assert/retract`、副作用不回溯、记忆化](docs/17-database.md) |
| 18 | [定子句文法：`-->`、`{}/1`、展开原理](docs/18-dcg.md) |
| 19 | [写一个解析器：词法 → AST → 求值 → 反向生成](docs/19-parser.md) |
| 20 | [异常处理：`throw/catch`、分类捕获、`some/none`](docs/20-exceptions.md) |
| 21 | [约束求解 CLP(FD)：域 → 约束 → 标号、可移植适配层](docs/21-constraints.md) |
| 22 | [模块与工程组织：命名空间冲突、加载边界、手写加载器](docs/22-modules.md) |
| 23 | [测试：迷你框架、框架自检、性质测试](docs/23-testing.md) |
| 24 | [综合项目：一个四百行的解释器](docs/24-capstone.md) |

## 怎么跑

```bash
./run-all.sh                  # 全量：23 个示例 × 三通道，只打摘要
./run-all.sh -v               # 附每个通道抽出的输出区间
./run-all.sh 07 21            # 只跑指定编号
./run-all.sh -Clean           # 清理 build/

pwsh ./build.ps1 -All         # PowerShell 等价入口
pwsh ./build.ps1 -Example 21  # 单个示例（含该章的观察通道）
pwsh ./build.ps1 -Verbose     # 附输出区间
pwsh ./build.ps1 -Clean
pwsh ./build.ps1 -Help
```

单跑某一章，也可以直接敲命令（`02_hello` 为例）：

```bash
# 通道 1：SWI 解释执行
swipl -Dencoding=utf8 -q -f examples/02_hello/02_hello.pl \
      -g "set_stream(user_output,encoding(utf8)),main" -t halt

# 通道 2：GNU 解释执行
gprolog --consult-file examples/02_hello/02_hello.pl --entry-goal main

# 通道 3：gplc 编译成本地可执行文件（只在当前目录可靠工作）
{ echo ':- initialization(main).'; cat examples/02_hello/02_hello.pl; } > build/02.pl
cd build && gplc 02.pl -o 02.bin && ./02.bin < /dev/null
```

> **两个必须知道的坑**：`gplc` 只在**当前目录**可靠工作（源文件放子目录会链接失败，
> 所以脚本会先拼一份到 `build/`）；没有 `:- initialization(main).` 的产物会掉进
> 交互式 toplevel **永久挂死**，所以脚本必须重定向 stdin。

## 验证

三条通道共用同一套判定，**六条全过**才算通过：

| # | 判定 |
|---|---|
| 1 | 退出码为 **0** |
| 2 | **stderr 为空** —— 连一个 singleton 变量警告都不许有 |
| 3 | stdout 同时出现 `==== NN 开始 ====` 与 `==== NN 结束 ====` |
| 4 | 两条标记之间（**输出区间**）非空，且不含 CR / ESC 等控制字符 |
| 5 | 区间内不出现 `uncaught` / `command-line goal` / `异常:` / `运行失败` 等溃逃痕迹 |
| 6 | **三条通道抽出的输出区间逐字节相同** |

第 6 条是本教程最硬的写作纪律：GNU 把 banner 与编译进度写进 stdout，两套引擎的变量编号
（`_A` vs `_G123`）、浮点打印位数、错误项形状又各不相同。所以约定
**示例只打印「两套引擎必然一致」的内容，并用两条标记圈起来**，脚本抽区间再逐字节比对。
这条纪律逼着你「断言性质」而不是「打印环境相关的数字」—— 你看到的每一份输出
在任何机器上都应当逐字节相同。

> 第 21、22 章有**已知噪声例外**：`use_module/library(clpfd)` 的警告、
> GNU `consult` 的编译进度，都落在两条标记**之外**，不影响区间比对。
> 输入文件本身（如 `/tmp/prolog_tutorial_22_geo.pl`）也是故意留在标记外的。

## 工具链

| 工具 | 路径 | 版本 | 用途 |
|---|---|---|---|
| `swipl` | `/opt/local/bin/swipl` | SWI-Prolog 10.0.2 | 解释执行，库最全，开发首选 |
| `gprolog` | `/opt/local/bin/gprolog` | GNU Prolog 1.5.0 | 解释执行，内建 FD 约束求解器 |
| `gplc` | `/opt/local/bin/gplc` | 随 GNU Prolog 1.5.0 | 编成无运行时依赖的本地可执行文件 |
| `pwsh` | `/opt/local/bin/pwsh` | PowerShell 7.6.6 | 跑 `build.ps1` |

```bash
sudo port install swi-prolog gprolog   # macOS MacPorts（本机即此）
brew install swi-prolog                # macOS Homebrew（GNU Prolog 需自行编译）
apt install swi-prolog gprolog         # Debian / Ubuntu
```

> **Windows 说明**：`swipl` 用 `scoop install swi-prolog` 即可。
> **GNU Prolog 没有官方 Windows 构建**，`gprolog` / `gplc` 两条通道不可用 ——
> `run-all.sh` / `build.ps1` 会自动跳过缺失的工具，无需改动。
> 所以 Windows 上你看到的是**单通道验证**：结论仍然有效，只是少了交叉比对。

## 当前状态

- **macOS**（darwin）：**119 项全部通过**。
  23 个示例 × 5 项（3 条通道 + 2 组区间一致：swipl=gprolog、swipl=gplc）
  + 第 21、22 章的 4 个观察通道 = 119。
- `run-all.sh` 与 `build.ps1` 两种入口均实测，结果**逐项一致**（同为 119/0）。
- 全部 226 条坑位都在两套引擎上实测过，不是抄来的。

## 怎么读

**先读正文 → 立刻 `./run-all.sh NN` 跑一遍 → 改两行再跑。**

- **第一次接触逻辑编程**：02 → 03 → 05 → 06，到这里你会对「合一 + 回溯」有体感。
- **已经会别的语言**：直接看 04（项）和 07（算术），这两章是思维转换的关键。
- **想快速用起来**：08（列表）、10（剪枝）、13（收集解）覆盖日常八成写法。
- **做解析**：18–19，从 DCG 识别器做到完整计算器。
- **做规则/推理系统**：17（动态库）+ 12（元编程）。
- **写可移植代码**：21、22、23 与每章末尾的坑位清单，外加 `CHEATSheet.md`。

## 相关教程

同仓库：[haskell](../haskell/)、[julia](../julia/)、[elixir](../elixir/)、
[clojure](../clojure/)、[erlang](../erlang/)、[rust](../rust/) 等
（同一结构标准：24 章分章 + 章号=示例号 + 坑位清单 + 多层验证）。
