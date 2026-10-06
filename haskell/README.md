# Haskell 教程（GHC 9.14.1）

纯函数式 · 强静态类型 · 惰性求值——从零教到能写解释器的程度。
以 Richard Bird《Haskell函数式程序设计》（*Thinking Functionally with Haskell* 中译本）
12 章为纲：数独、证明与归纳、无穷列表、State/ST、手写解析器组合子、**等式计算器**、
优美打印等"函数式思维"核心全部自包含提炼（不要求翻原书，每章附精选练习）；
工程线（Stack/TH/并发/FFI/测试）为现代扩充。
定位：**会编程（C++/Python 背景最佳）、初学 Haskell**；所有示例在 Windows 11 + GHC 9.14.1
（scoop）+ stack 3.11.1（清华镜像），以及 macOS 14 + GHC 9.14.1（MacPorts）+ stack 3.11.1
实测通过。主线只用 GHC 自带 boot 库（mtl/parsec/text/stm/containers…），离线可验证。
FFI 章（30）用 CPP 分平台：Windows 直链 msvcrt/kernel32，macOS/Linux 用 libc + nanosleep。

## 目录结构

```
haskell/
  docs/        31 章正文（六篇，01 → 31 顺序阅读；章号 = 示例目录号）
  examples/    30 个示例目录（02–31；27/31 为 stack 工程）
  materials/   取材（book/＝Bird 书全书 OCR 文本，仅写作查证用）
  tools/       重编号与导航审计脚本
  build.ps1    验证脚本（pwsh 7；-All / -Example NN_topic / -Clean）
  run-all.sh   bash 版双入口
  CHEATSheet.md 语法速查 + 实测坑位索引
```

每个示例目录（非 stack 章）：`ChNN.hs`（库模块）+ `main.hs`（演示 + 自检 + 结束标记）+
`runtests.hs`（断言套件）——"库 + 双 Main"是 27 章 stack 工程的最小形态。
27/31 为完整 stack 工程（库 + 可执行 + 测试三件套）。

## 章节索引（六篇）

| 章 | 主题 | ⭐ | 书源 |
|---|---|---|---|
| **一 语言基础** | | | |
| [01 全景](docs/01-overview.md) | 定位、血统、生态、本机工具链 | | 书1 |
| [02 第一个程序](docs/02-hello.md) | 三态运行、编码坑、GHCi 会话、getArgs | | 书2 |
| [03 数值](docs/03-numbers.md) | 类型类层次、取整家族、自然数 | | 书3 |
| [04 控制流](docs/04-control.md) | 表达式化、guard、递归与累加器 | | |
| [05 函数](docs/05-functions.md) | 柯里化、组合、sections | | |
| [06 模式匹配](docs/06-patterns.md) | 构造子/守卫/as/视图模式 | ⭐ | |
| [07 代数数据类型](docs/07-adt.md) | 和/积/递归/记录语法 | ⭐ | |
| [08 类型类](docs/08-typeclasses.md) | 类型类与 deriving | ⭐ | |
| **二 列表与推理** | | | |
| [09 列表与折叠](docs/09-lists.md) | 语法糖、原语族、经典定义、折叠 | ⭐ | 书4 |
| [10 数独解题器](docs/10-sudoku.md) | 实战：矩阵建模、剪枝搜索 | ⭐ | 书5 |
| [11 证明与归纳](docs/11-proofs.md) | 等式推理、归纳法、融合律 | ⭐ | 书6 |
| [12 惰性求值](docs/12-laziness.md) | thunk、空间泄漏、严格性 | ⭐ | |
| [13 无穷列表](docs/13-infinite.md) | 循环结构、筛法、流式策略 | ⭐ | 书9 |
| [14 容器](docs/14-containers.md) | Map/Set/Foldable/Traversable | | |
| [15 字符串](docs/15-strings.md) | String/Text/ByteString 三件套 | ⭐ | |
| **三 单子与结构** | | | |
| [16 函子·应用·单子](docs/16-fam.md) | 三部曲 + 手写 State | ⭐ | |
| [17 单子变换器](docs/17-mtl.md) | mtl 风格 + 手写 xorshift | ⭐ | |
| [18 命令式函数式：State 与 ST](docs/18-st.md) | ST 单子、STRef/STArray、runST | ⭐ | 书10 |
| [19 文件](docs/19-files.md) | 读写、句柄坑、目录、临时文件 | | |
| [20 错误处理](docs/20-errors.md) | Either/异常/bracket | | |
| **四 解析与实战** | | | |
| [21 手写解析器组合子](docs/21-miniparser.md) | 从零实现 Parser 与表达式文法 | ⭐ | 书11 |
| [22 parsec](docs/22-parsec.md) | 库用法：try/lexeme/buildExpressionParser | ⭐ | |
| [23 等式计算器](docs/23-calculator.md) | 实战：点自由定律的自动证明器 | ⭐ | 书12 |
| **五 工程与性能** | | | |
| [24 Template Haskell](docs/24-th.md) | 引号/reify/GHC.Generics | ⭐ | |
| [25 性能](docs/25-performance.md) | 惰性代价、累积参数、元组化、profiling | ⭐ | 书7 |
| [26 优美打印](docs/26-pretty.md) | 实战：Doc 代数与高效布局 | ⭐ | 书8 |
| [27 Stack 工程](docs/27-stack.md) | 工程与生态（镜像链路实测） | ⭐ | |
| [28 测试](docs/28-testing.md) | 自制框架 + mini-QuickCheck | | |
| [29 并发与 STM](docs/29-concurrency.md) | 线程/MVar/STM | ⭐ | |
| [30 FFI](docs/30-ffi.md) | 调 C（Win msvcrt/kernel32 · macOS/Linux libc+nanosleep） | | |
| **六 收官** | | | |
| [31 实战：MiniLang](docs/31-capstone.md) | 迷你解释器（词法/语法/求值/REPL） | ⭐ | |

原书 12 章映射：书1→01、书2→02、书3→03、书4→09、书5→10、书6→11、书7→25、
书8→26、书9→13、书10→18、书11→21、书12→23。

## 工具链（本机实测）

| 项 | Windows | macOS |
|---|---|---|
| GHC | 9.14.1 @ `G:\scoop\apps\haskell\current` | 9.14.1 @ MacPorts（`/opt/local/bin`） |
| stack | 3.11.1 + 清华 TUNA 镜像（stackage 域被墙，见 27 章） | 3.11.1（`--system-ghc --compiler` 覆盖版本钉） |
| 编码 | 示例开头 `hSetEncoding stdout/stderr utf8`（控制台默认 GBK） | 同左；另需 UTF-8 locale，否则写中文文件抛异常 |
| 依赖 | 主线纯 boot 库；hackage 生态只作介绍 | 同左 |

> **macOS 编码坑**：`LANG/LC_*` 全空时 GHC 文件句柄退化为 ASCII，`writeFile "初始化"`（27 章）
> 会抛 `cannot encode character`。正常终端默认 UTF-8 无碍；`run-all.sh` 已在未设 locale 时兜底
> `LANG=en_US.UTF-8`。**stack 版本钉**：`stack.yaml` 钉 `ghc-9.14.1`，换机版本不符会报
> `No compiler found`；`run-all.sh` 用系统 GHC 版本命令行覆盖，直接 `stack build` 时需自加
> `--system-ghc --compiler=ghc-$(ghc --numeric-version)`。

## 验证

```bash
pwsh ./build.ps1 -All                 # Windows 全量：30 示例 × 运行层+测试层
pwsh ./build.ps1 -Example 22_parsec   # 单个示例
bash run-all.sh                       # bash 入口（macOS/Linux；自动兜底 locale + stack 版本）
```

判定六条：编译 0 / 运行 0 / stderr 空 / stdout 非空无控制字符 / 结束标记 / 无 GHC 诊断字样。

## 相关教程

同仓库：[cpp20](../cpp20/)、[rust](../rust/)、[julia](../julia/)、[swift](../swift/) 等
（同一结构标准：分章 docs + 章号=示例号 + 坑位清单 + 多层验证）。
