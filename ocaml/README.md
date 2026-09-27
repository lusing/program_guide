# OCaml 教程与示例

OCaml 入门到进阶，**41 章分章文档 + 36 个可运行示例**。全部示例在字节码编译器（`ocamlc`）、原生编译器（`ocamlopt`）与顶层解释器（`ocaml`）三种方式下验证通过；验证环境：

- **Windows 11 + MSYS2 UCRT64，OCaml 5.4.1**（全量三通道全绿）
- **macOS 12.7 / 14.8.9 (Darwin x86_64) + MacPorts，OCaml 5.5.0**（2026-09-20 首测，2026-09-27 在 14.8.9 上三通道复测，`run-all.sh --interp` 通过 107 / 失败 0）：
  两个入口结论一致，零告警、零 stderr 差异

macOS 侧唯一需要留意的差异是：**用到 `Unix` 模块的示例必须显式写 `-I +unix`**，否则 OCaml 5 会吐 `Alert ocaml_deprecated_auto_include`（属于告警，会被「编译日志为空」这条判定拦下）。两个入口都已内置 unix 依赖表。

这里不是「语法速览」。模块系统（`module` / `signature` / `functor` / `include`）、首类模块、GADT、OCaml 5 的 Domain 并行、Effect 效应处理器与内存模型、绑定运算符（`let*` / `and*`）、错误处理、ocamllex 生成式词法分析，都在示例里实打实跑过。

**2026-09 两轮扩充**：

- **第 31–35 章按书扩充**（书本篇）：按《OCaml 语言编程基础教程》（陈钢、张静著，人民邮电出版社 2018）第 2.11–2.12、3.9–3.12、4.5、4.10–4.11、8.1–8.14 节——标签参数与可选参数、延迟求值、模块表达式与抽象类型深水区、弱多态与四向链表、面向对象进阶。书的第 5–7 章（Graphics 图形编程、移植 F#、C# 互操作）平台绑定强、无法无头三通道验证，未纳入；图形案例在示例 31 中改写为控制台等价版本。另参考 Real World OCaml 中文翻译第 1–10 章。
- **第 36–40 章按官方手册扩充**（manual 篇）：按 OCaml 官方仓库 manual 源码（`G:\github\lang\ocaml\manual`）的 tutorials 与 refman 语言扩展——`%a` 自定义打印机与 Format 盒子、多态变体深水区、显式多态与类型注记（rank-2 / variance / `type nonrec` / inline record / extensible variant）、语言扩展拾遗（generative functor / `open!` / `let exception` / `{< >}` / refutation case / 字面量全集 / `module rec`）、OCaml 5 内存模型（happens-before / DRF-SC / `[@atomic]` 字段）。

## 目录结构

```text
ocaml/
├── README.md                 本文件
├── build.ps1                 PowerShell 构建/验证入口（跨平台）
├── run-all.sh                shell 构建/验证入口（与 build.ps1 判定完全一致）
├── docs/                     01–41 章分章文档
│   ├── 01-overview.md        认识 OCaml
│   ├── 02-toolchain.md       工具链与三种运行方式（2.8 Windows/MSYS2 六坑）
│   ├── 03 .. 30              核心语言 → 模块 → 并发 → ocamllex（章号 = 示例号 + 2）
│   ├── 31 .. 35              书本篇进阶（按陈钢/张静教材扩充）
│   ├── 36 .. 40              manual 篇进阶（按官方手册扩充）
│   └── 41-pitfalls.md        坑清单与最佳实践（13 节）
└── examples/                 36 个示例
    ├── 01_basics.ml .. 25_domains_effects.ml   单文件示例
    ├── 26_ocamllex/          ocamllex 两段式（.mll + main.ml）
    ├── 27_labeled_args.ml .. 31_objects_advanced.ml   书本篇配套
    └── 32_pp_printers.ml .. 36_memory_model.ml        manual 篇配套
```

## 章节索引

| 章 | 主题 | 示例 |
|---|---|---|
| [01 认识 OCaml](docs/01-overview.md) | 定位、ML 家族谱系、三范式合一 | — |
| [02 工具链与运行方式](docs/02-toolchain.md) | 三种运行方式、utop、opam、dune；**2.8 Windows/MSYS2 实战六坑** | — |
| [03 程序结构与求值](docs/03-structure.md) | `let` 绑定、`let ... in`、类型推断、求值顺序 | 01_basics |
| [04 类型系统](docs/04-types.md) | 基础类型、类型别名、多态、值限制 | 02_types |
| [05 表达式与运算符](docs/05-expressions.md) | 优先级、`~-`、`/` 与 `/.`、短路、`if` 是表达式 | 03_expressions |
| [06 元组与记录](docs/06-tuples-records.md) | 解构、`mutable` 字段、`with` 复制更新 | 04_tuples |
| [07 模式匹配](docs/07-patterns.md) | `match`/`function`、`as`、`when`、穷尽性 | 05_patterns |
| [08 列表与高阶列表函数](docs/08-lists.md) | `::` 与 `@`、map/filter/fold | 06_lists |
| [09 变体类型](docs/09-variants.md) | 代数数据类型、递归类型、多态变体 | 07_variants |
| [10 字符串与字符](docs/10-strings.md) | String 模块、Printf、Bytes | 08_strings |
| [11 递归与尾递归](docs/11-recursion.md) | 尾递归与累积器、互递归、Ackermann、汉诺塔 | 09_recursion |
| [12 异常](docs/12-exceptions.md) | raise / try...with、`exn` 可扩展变体、异常 vs option | 10_exceptions |
| [13 高阶函数与闭包](docs/13-higher-order.md) | 柯里化、闭包、`@@` / `|>` | 11_higher_order |
| [14 模块与签名](docs/14-modules.md) | module / module type、open、include、首类模块 elt/t 模式 | 12_modules |
| [15 Functor（函子）](docs/15-functors.md) | 参数化模块、sharing constraint、Set/Map 原理 | 13_functors |
| [16 不透明约束与抽象数据类型](docs/16-abstraction.md) | `:` vs `:>`、不变量保护（见第 14–15 章指南） | — |
| [17 模块系统进阶](docs/17-modules-advanced.md) | open 遮蔽、`module type of`、首类模块（见第 14–15 章指南） | — |
| [18 可变状态](docs/18-mutable.md) | ref / Array / Hashtbl / Buffer、物理 vs 结构相等 | 14_mutable |
| [19 排序与经典算法](docs/19-algorithms.md) | 三排序互证、二分、筛法、记忆化 | 15_algorithms |
| [20 数值计算](docs/20-numeric.md) | 二分法/牛顿法、积分、克拉默、浮点三坑 | 16_numeric |
| [21 解析：词法与递归下降](docs/21-parsing.md) | 手写词法器、递归下降、词频 | 17_parsing |
| [22 输入输出与文件](docs/22-io.md) | 读写、Printf/Scanf、Sys、资源清理 | 18_io |
| [23 测试与断言](docs/23-testing.md) | 断言框架、属性测试、测试报告 | 19_testing |
| [24 记录、对象与类](docs/24-objects.md) | 函数字段、`object`、`class`、结构继承、开放对象类型坑 | 20_records |
| [25 流与序列](docs/25-streams.md) | Seq 惯用法、Stream 兼容层、管道式处理 | 21_streams_seq |
| [26 综合实战：成绩 CSV 分析](docs/26-project.md) | 解析、统计、Top-N、最小二乘、报告写回 | 22_project |
| [27 错误处理与绑定运算符](docs/27-error-handling.md) | option/result、let*/and*/let+ 接线、Validation 累积 | 23_error_handling |
| [28 GADT](docs/28-gadts.md) | 类型索引、typed AST、eq 见证、多态递归 | 24_gadts |
| [29 OCaml 5 并发](docs/29-domains-effects.md) | Domain/Atomic/Mutex、并行求和、Effect 全解 | 25_domains_effects |
| [30 ocamllex](docs/30-ocamllex.md) | .mll 规则、最长匹配、构建链、模块名陷阱 | 26_ocamllex |
| [31 带标签的函数参数与可选参数 ⭐](docs/31-labeled-args.md) | `~x` / `?(x=e)` / `?x` 转发、高阶标签限制、ListLabels 家族 | 27_labeled_args |
| [32 延迟求值：lazy 与延迟流 ⭐](docs/32-lazy.md) | lazy/force/记忆化、异常不缓存、延迟流 vs Seq | 28_lazy_eval |
| [33 模块表达式与抽象类型 ⭐](docs/33-module-exprs.md) | 首类模块、私有抽象、局部抽象、`with type :=`、多参数函子 | 29_module_exprs |
| [34 命令式进阶 ⭐](docs/34-imperative-deep.md) | 弱多态实测、四向链表（CNF）、Hashtbl/Stack/Queue 三实现 | 30_imperative_deep |
| [35 面向对象进阶 ⭐](docs/35-objects-deep.md) | 多重继承、延迟绑定、虚拟类、子类型、二元方法 | 31_objects_advanced |
| [36 美化打印：%a 与 Format 盒子 ◆](docs/36-pp-printers.md) | pp 组合子、盒子/断点、优先级感知打印机、Format 三大实测坑 | 32_pp_printers |
| [37 多态变体深水区 ◆](docs/37-poly-variants.md) | row type 上下界、`as 'a` 共享、交类型、`#type` 模式、弱点 | 33_poly_variants |
| [38 显式多态与类型注记 ◆](docs/38-explicit-poly.md) | `'a. τ` 多态递归、rank-2 打包、variance、`type nonrec`、inline record、extensible variant | 34_explicit_poly |
| [39 语言扩展拾遗 ◆](docs/39-lang-ext.md) | generative functor、`open!`/generalized open、`let exception`、`{< >}`、refutation case、字面量全集、`module rec` | 35_lang_ext |
| [40 OCaml 5 内存模型 ◆](docs/40-memory-model.md) | happens-before、数据竞争、DRF-SC、`[@atomic]` 字段（5.4+） | 36_memory_model |
| [41 坑清单与最佳实践](docs/41-pitfalls.md) | 语法/类型/模块/结构/运算符/GADT/标签对象/Format 与扩展/平台十三节 | — |

⭐ = 2026-09 按《OCaml 语言编程基础教程》（陈钢、张静）扩充的书本篇。
◆ = 2026-09-27 按官方手册（manual）扩充的 manual 篇。

## 工具链

| 工具 | Windows（MSYS2 UCRT64） | macOS / Linux 候选 | 定位 |
|---|---|---|---|
| `ocaml` | `<msys2>\ucrt64\bin\ocaml.exe` | `/opt/local/bin`、`/opt/homebrew/bin`、`/usr/local/bin`、`/usr/bin` | 顶层解释器（REPL）/ 脚本执行 |
| `ocamlc` | 同上目录 | 同上 | 字节码编译器，编译快、便于验证 |
| `ocamlopt` | 同上目录（需 flexdll 包） | 同上 | 原生编译器，生成高性能可执行文件 |
| `ocamllex` | 同上目录 | 同上 | 词法分析器生成器（示例 26） |

本机实测（macOS）：MacPorts 装在 `/opt/local/bin`，`ocamlc -version` = 5.5.0，`ocamlc -where` = `/opt/local/lib/ocaml`。两个入口的探测顺序都是**环境变量（`OCAMLC` / `OCAMLOPT` / `OCAML` / `OCAMLLEX`）→ PATH → 常见安装目录**。

验证安装：

```bash
ocaml -version           # 查看 OCaml 版本
ocamlc -version          # 查看字节码编译器版本
ocamlopt -version        # 查看原生编译器版本
```

> **Windows 注意**：从 PowerShell / CMD 直接调用 MSYS2 版编译器，必须设置 `OCAMLLIB`（否则报 `Unbound module Stdlib`）；原生编译需要单独安装 `mingw-w64-ucrt-x86_64-flexdll`。完整实战与实测坑见[第 2 章](docs/02-toolchain.md) 2.8 节。`build.ps1` 会自动发现工具链并处理这些（含本次新增：字节码产物无 `.exe` 后缀时自动补副本再运行）。

## 构建与验证

两个入口等价：`build.ps1`（PowerShell，跨平台）与 `run-all.sh`（shell）。两者**都真的编译并运行**每个示例（不只是编译），产物与日志落在 `build/`。

| 命令 | 说明 |
|---|---|
| `pwsh ./build.ps1 -All` | 编译 + 运行全部示例（字节码） |
| `pwsh ./build.ps1 -All -Native` | 追加 ocamlopt 原生通道 |
| `pwsh ./build.ps1 -All -Interp` | 追加顶层解释器通道 |
| `pwsh ./build.ps1 -All -NoRun` | 只编译不运行 |
| `pwsh ./build.ps1 -File 01` | 编译单个示例（写编号或全名均可） |
| `pwsh ./build.ps1 -File 26` | ocamllex 组合示例（两段式构建） |
| `pwsh ./build.ps1 -Clean` | 清理 build 目录 |
| `./run-all.sh` | 等价的 shell 入口（字节码 + 原生） |
| `./run-all.sh --interp` | 追加顶层解释器通道 |
| `./run-all.sh --byte` | 只跑字节码通道（快） |
| `./run-all.sh --no-run` | 只编译不运行（只判「编译退出码 0 + 零告警」两条） |
| `./run-all.sh 01 25` | 只跑指定编号 |
| `./run-all.sh -v` | 附每个示例的完整输出 |

通道说明：`26_ocamllex` 是多文件示例，只有 byte / native 两个通道（解释器跑不了两段式构建），所以「全通道」是 **35×3 + 2 = 107** 条。

### 判定标准（两个入口逐条一致）

1. **编译退出码为 0**
2. **编译日志为空** —— 零告警；示例代码必须 warning-free
3. **运行退出码为 0**
4. **运行 stderr 为空**
5. **stdout 非空**，且无多余控制字符（TAB / LF / CR 除外）
6. **stdout 出现结束标记** `==== NN jieshu ====` —— 程序完整执行到结尾

依赖 `Unix` 模块的示例（15/18/21/22/25）自动加 `-I +unix unix.cma` / `unix.cmxa`。失败时两个入口都返回退出码 1，可以直接拿去做回归。

> 为什么没有「两通道输出逐字节比对」：byte 与 native 是**同一套编译器**的两个后端，差异只可能来自编译器自身；而 18 号示例会打印 `Sys.argv.(0)`（`build/18_io` vs `build/18_io_opt`）、15/21/25 号会打印耗时，逐字节比对只会产生噪声。因此改用「三通道各自独立判定」+ 多轮稳定性复跑。

### 手工编译（等价命令）

```bash
ocaml -w -24 examples/01_basics.ml                                # 解释执行
ocamlc -w -24 -o build/01_basics examples/01_basics.ml            # 字节码
ocamlopt -w -24 -o build/01_basics_opt examples/01_basics.ml      # 原生
ocamlc -w -24 -I +unix unix.cma -o build/15_algorithms examples/15_algorithms.ml
```

> **OCaml 5 起 `-I +unix` 不能省**：不写会吐 `Alert ocaml_deprecated_auto_include`（unix 子目录被自动加入搜索路径的弃用提示），它是**告警**，会被第 2 条判失败。

> 关于中文：本教程的字符串字面量里只写 ASCII，中文全部放注释。这样可以确保代码在所有 OCaml 实现和环境中都能正确编译运行。

## 当前状态

- 36 个示例：Windows（MSYS2 UCRT64, OCaml 5.4.1）三通道全绿
- 2026-09-27 第一轮（按书）：新增 27–31 号示例与第 31–35 章
  （标签参数、延迟求值、模块表达式与抽象类型、命令式进阶、
  面向对象进阶）
- 2026-09-27 第二轮（按手册）：新增 32–36 号示例与第 36–40 章
  （美化打印 `%a`/Format、多态变体深水区、显式多态与类型注记、
  语言扩展拾遗、OCaml 5 内存模型），坑清单顺延为第 41 章
- 手册轮代表性实测发现（详见各章「实测坑」）：
  - Format 顶层裸断点**恒换行**（断点只在盒内有「能塞就不换」
    语义）；`set_margin` 收紧会连带压低 `max_indent` 且不随 margin
    恢复（默认几何 78/68）；连续 `Format.printf` 不 flush 会跨调用
    累积列计数导致盒子误竖排
  - Printf 与 Format 两家族的 `%a` 打印机类型不通用、缓冲独立
    （混用输出乱序）
  - `let` 位置的多态变体模式会把 row 闭口
  - 同一编译单元同名类型二次定义：interp 过、编译不过
    （`type nonrec` 演示须包嵌套模块）
  - 非原子竞争实测丢 5–6 万次更新（静默算错）；Atomic / Mutex /
    `[@atomic]` 记录字段（5.4+）三修法全部精确
- 第一轮（按书）代表性实测发现：
  - `Hashtbl.replace` / `remove` 一次只动**最近一个**绑定，更早的
    重复键原样保留（与「清光重挂」的直觉相反）
  - `let g = f 1` 是弱类型（`'b` 在逆变位置）；`id id` **不**泛化；
    `List.map (fun x -> x) []` 反而泛化（relaxed value restriction
    只放行协变位置）
  - 顶层 `let module P = e`（无 `in`）是 Syntax error，要用
    `module P = (val m : S)`
  - lazy 的**异常不记忆化**：每次 force 都重新执行并重抛
  - 二元方法 `object(self : 'a)` 使子类失去对父类的子类型关系
    （`(b : e4 :> e3)` 编译不过）——子类未必是子类型
- macOS（12.7 x86_64 + MacPorts, OCaml 5.5.0）2026-09-20 实测：
  两个入口全绿，零告警（扩充前基线；新增 10 个示例中仅
  36_memory_model 的 `[@atomic]` 字段需要 OCaml ≥ 5.4）
- macOS（14.8.9 x86_64 + MacPorts, OCaml 5.5.0 非 flambda）2026-09-27 复测：
  两个入口各自三通道 107 项全通过（36 示例 byte+native，
  35 单文件示例另走解释器，26 多文件跳过），零告警、零 stderr 差异；
  `run-all.sh --interp` 与 `pwsh build.ps1 -All -Native -Interp`（PowerShell 7.6.6）结论一致
- 初版 12–22 号示例存在与平台无关的结构性语法错误（顶层
  `let ... in`、缺 `;;`、无效 package type 等），已全部修复并
  计入第 36 章坑清单
- 反向验证：造 6 个坏样例（缺结束标记 / 写 stderr / 退出码 1 /
  stdout 含 NUL+ESC / 编译有告警 / 退出码 0 但无输出），
  两个入口**全部报 FAIL 且理由正确**，验完删除
