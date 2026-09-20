# OCaml 教程与示例

OCaml 入门到进阶，配套 **26 个可运行示例**，教程正文 **31 章**。
全部示例在字节码编译器（`ocamlc`）、原生编译器（`ocamlopt`）与顶层
解释器（`ocaml`）三种方式下验证通过；验证环境：

- **Windows 11 + MSYS2 UCRT64，OCaml 5.4.1**（26/26 字节码 + 25/25 原生全绿）
- **macOS 12.7 (Darwin x86_64) + MacPorts，OCaml 5.5.0**（2026-09-20 实测）：
  两个入口各 **77/77 全绿**（25 个示例 × 3 通道 + ocamllex 示例 × 2 通道），
  零告警、零 stderr 差异，`./run-all.sh` 与 `pwsh ./build.ps1 -All` 结论一致

macOS 侧唯一需要留意的差异是：**用到 `Unix` 模块的示例必须显式写 `-I +unix`**，
否则 OCaml 5 会吐 `Alert ocaml_deprecated_auto_include`（属于告警，会被
「编译日志为空」这条判定拦下）。两个入口都已内置 unix 依赖表。

这里不是「语法速览」。模块系统（`module` / `signature` / `functor` /
`include`）、首类模块、GADT、OCaml 5 的 Domain 并行与 Effect 效应
处理器、绑定运算符（`let*` / `and*`）、错误处理、ocamllex 生成式
词法分析，都在示例里实打实跑过。

## 目录结构

```
ocaml/
├── README.md                 本文件
├── OCaml编程指南.md          教程正文（31 章）
├── build.ps1                 PowerShell 构建/验证入口（跨平台）
├── run-all.sh                shell 构建/验证入口（与 build.ps1 判定完全一致）
└── examples/
    ├── 01_basics.ml              程序结构、let 绑定、类型推断、注释
    ├── 02_types.ml               基础类型、类型标注、类型别名、多态
    ├── 03_expressions.ml         运算符与优先级、整数/浮点数除法、&&/||
    ├── 04_tuples.ml              元组与记录、字段访问、解构、可变字段
    ├── 05_patterns.ml            模式匹配全谱：通配、构造子、as、when、嵌套
    ├── 06_lists.ml               列表构造、List.map/filter/fold_left/fold_right
    ├── 07_variants.ml            variant 类型、参数化构造子、多态变体、递归类型
    ├── 08_strings.ml             字符串与字符、String 模块、Printf 格式化
    ├── 09_recursion.ml           尾递归与累积器、互递归、Ackermann、汉诺塔
    ├── 10_exceptions.ml          raise、try...with、异常参数、Printexc
    ├── 11_higher_order.ml        柯里化、偏应用、闭包、函数组合、管道运算符
    ├── 12_modules.ml             module / signature、透明约束、open、include、
    │                              首类模块（elt/t 分离签名）
    ├── 13_functors.ml            functor、参数化模块、sharing constraint
    ├── 14_mutable.ml             ref / Array / Hashtbl、物理相等 vs 结构相等
    ├── 15_algorithms.ml          插入/归并/快速排序、二分查找、筛法、记忆化
    ├── 16_numeric.ml             二分法/牛顿法、数值积分、克拉默法则、插值
    ├── 17_parsing.ml             词法分析 + 递归下降求值器、词频统计
    ├── 18_io.ml                  标准 I/O、文件读写、Printf、Scanf、目录操作
    ├── 19_testing.ml             断言框架、异常断言、属性测试、测试报告
    ├── 20_records.ml             记录高级用法、对象（object）、类（class）
    ├── 21_streams_seq.ml         Seq 惰性序列、Stream 流（带 Seq 兼容层）、
    │                              管道式数据处理
    ├── 22_project.ml             综合实战：成绩 CSV 分析与报告
    ├── 23_error_handling.ml      option/result、let*/and*/let+ 绑定运算符、
    │                              自制 Validation 错误累积
    ├── 24_gadts.ml               类型索引构造子、typed AST、类型相等见证、
    │                              异构列表、多态递归
    ├── 25_domains_effects.ml     Domain 并行、Atomic/Mutex、并行求和、
    │                              Effect：状态效应/控制反转/一次性续延
    └── 26_ocamllex/              ocamllex 生成式词法分析
        ├── ocamllex_expr.mll     词法规则（模块名须合法，故在子目录）
        └── main.ml               token 流、错误定位、递归下降求值器
```

## 工具链

| 工具 | Windows（MSYS2 UCRT64） | macOS / Linux 候选 | 定位 |
|---|---|---|---|
| `ocaml` | `<msys2>\ucrt64\bin\ocaml.exe` | `/opt/local/bin`、`/opt/homebrew/bin`、`/usr/local/bin`、`/usr/bin` | 顶层解释器（REPL）/ 脚本执行 |
| `ocamlc` | 同上目录 | 同上 | 字节码编译器，编译快、便于验证 |
| `ocamlopt` | 同上目录（需 flexdll 包） | 同上 | 原生编译器，生成高性能可执行文件 |
| `ocamllex` | 同上目录 | 同上 | 词法分析器生成器（示例 26） |

本机实测（macOS）：MacPorts 装在 `/opt/local/bin`，`ocamlc -version` = 5.5.0，
`ocamlc -where` = `/opt/local/lib/ocaml`。两个入口的探测顺序都是
**环境变量（`OCAMLC` / `OCAMLOPT` / `OCAML` / `OCAMLLEX`）→ PATH → 常见安装目录**。

验证安装：

```bash
ocaml -version           # 查看 OCaml 版本
ocamlc -version          # 查看字节码编译器版本
ocamlopt -version        # 查看原生编译器版本
```

> **Windows 注意**：从 PowerShell / CMD 直接调用 MSYS2 版编译器，
> 必须设置 `OCAMLLIB`（否则报 `Unbound module Stdlib`）；原生编译
> 需要单独安装 `mingw-w64-ucrt-x86_64-flexdll`。完整实战与六个
> 实测坑见教程第 2.8 节。`build.ps1` 会自动发现工具链并处理这些。

## 构建与验证

两个入口等价：`build.ps1`（PowerShell，跨平台）与 `run-all.sh`（shell）。
两者**都真的编译并运行**每个示例（不只是编译），产物与日志落在 `build/`。

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

通道说明：`26_ocamllex` 是多文件示例，只有 byte / native 两个通道
（解释器跑不了两段式构建），所以「全通道」是 **25×3 + 2 = 77** 条。

### 判定标准（两个入口逐条一致）

1. **编译退出码为 0**
2. **编译日志为空** —— 零告警；示例代码必须 warning-free
3. **运行退出码为 0**
4. **运行 stderr 为空**
5. **stdout 非空**，且无多余控制字符（TAB / LF / CR 除外）
6. **stdout 出现结束标记** `==== NN jieshu ====` —— 程序完整执行到结尾

依赖 `Unix` 模块的示例（15/18/21/22/25）自动加 `-I +unix unix.cma` / `unix.cmxa`。
失败时两个入口都返回退出码 1，可以直接拿去做回归。

> 为什么没有「两通道输出逐字节比对」：byte 与 native 是**同一套编译器**的
> 两个后端，差异只可能来自编译器自身；而 18 号示例会打印 `Sys.argv.(0)`
> （`build/18_io` vs `build/18_io_opt`）、15/21/25 号会打印耗时，
> 逐字节比对只会产生噪声。因此改用「三通道各自独立判定」+ 多轮稳定性复跑。

### 手工编译（等价命令）

```bash
ocaml -w -24 examples/01_basics.ml                                # 解释执行
ocamlc -w -24 -o build/01_basics examples/01_basics.ml            # 字节码
ocamlopt -w -24 -o build/01_basics_opt examples/01_basics.ml      # 原生
ocamlc -w -24 -I +unix unix.cma -o build/15_algorithms examples/15_algorithms.ml
```

> **OCaml 5 起 `-I +unix` 不能省**：不写会吐 `Alert ocaml_deprecated_auto_include`
> （unix 子目录被自动加入搜索路径的弃用提示），它是**告警**，会被第 2 条判失败。

> 关于中文：本教程的字符串字面量里只写 ASCII，中文全部放注释。
> 这样可以确保代码在所有 OCaml 实现和环境中都能正确编译运行。

## 各章索引

| 章 | 主题 | 关键内容 |
|---|---|---|
| 1 | 认识 OCaml | OCaml 的定位、ML 家族谱系、三范式合一、工具链概览 |
| 2 | 工具链与运行方式 | 三种运行方式、utop、opam、dune；**2.8 Windows/MSYS2 实战六坑** |
| 3 | 程序结构与求值 | `let` 绑定、`let ... in`、类型推断、求值顺序（示例 01） |
| 4 | 类型系统 | 基础类型、类型别名、多态、值限制（示例 02） |
| 5 | 表达式与运算符 | 优先级、`~-`、`/` 与 `/.`、短路、`if` 是表达式（示例 03） |
| 6 | 元组与记录 | 解构、`mutable` 字段、`with` 复制更新（示例 04） |
| 7 | 模式匹配 | `match`/`function`、`as`、`when`、穷尽性（示例 05） |
| 8 | 列表与高阶列表函数 | `::` 与 `@`、map/filter/fold（示例 06） |
| 9 | 变体类型 | 代数数据类型、递归类型、多态变体（示例 07） |
| 10 | 字符串与字符 | String 模块、Printf、Bytes（示例 08） |
| 11 | 递归与尾递归 | 尾递归与累积器、互递归、Ackermann、汉诺塔（示例 09） |
| 12 | 异常 | raise / try...with、`exn` 可扩展变体、异常 vs option（示例 10） |
| 13 | 高阶函数与闭包 | 柯里化、闭包、`@@` / `|>`（示例 11） |
| 14 | 模块与签名 | module / module type、open、include、首类模块 elt/t 模式（示例 12） |
| 15 | Functor（函子） | 参数化模块、sharing constraint、Set/Map 原理（示例 13） |
| 16 | 不透明约束与抽象数据类型 | `:` vs `:>`、不变量保护（见第 14–15 章指南） |
| 17 | 模块系统进阶 | open 遮蔽、`module type of`、首类模块（见第 14–15 章指南） |
| 18 | 可变状态 | ref / Array / Hashtbl / Buffer、物理 vs 结构相等（示例 14） |
| 19 | 排序与经典算法 | 三排序互证、二分、筛法、记忆化（示例 15） |
| 20 | 数值计算 | 二分法/牛顿法、积分、克拉默、浮点三坑（示例 16） |
| 21 | 解析：词法与递归下降 | 手写词法器、递归下降、词频（示例 17） |
| 22 | 输入输出与文件 | 读写、Printf/Scanf、Sys、资源清理（示例 18） |
| 23 | 测试与断言 | 断言框架、属性测试、测试报告（示例 19） |
| 24 | 记录、对象与类 | 函数字段、`object`、`class`、结构继承、开放对象类型坑（示例 20） |
| 25 | 流与序列 | Seq 惯用法、Stream 兼容层、管道式处理（示例 21） |
| 26 | 综合实战：成绩 CSV 分析 | 解析、统计、Top-N、最小二乘、报告写回（示例 22） |
| 27 | 错误处理与绑定运算符 | option/result、let*/and*/let+ 接线、Validation 累积（示例 23） |
| 28 | GADT | 类型索引、typed AST、eq 见证、多态递归（示例 24） |
| 29 | OCaml 5 并发 | Domain/Atomic/Mutex、并行求和、Effect 全解（示例 25） |
| 30 | ocamllex | .mll 规则、最长匹配、构建链、模块名陷阱（示例 26） |
| 31 | 坑清单与最佳实践 | 语法/类型/模块/结构/运算符/GADT/Windows 七大类坑 |

## 当前状态

- 26 个示例：Windows（MSYS2 UCRT64, OCaml 5.4.1）字节码 26/26、
  原生 25/25 全绿
- macOS（12.7 x86_64 + MacPorts, OCaml 5.5.0）2026-09-20 实测：
  **两个入口各 77/77 全绿**，零告警
- 初版 12–22 号示例存在与平台无关的结构性语法错误（顶层
  `let ... in`、缺 `;;`、无效 package type 等），已全部修复并
  计入第 31 章坑清单
- 2026-09-20 macOS 校验修复的编译告警（与平台无关，Windows 上同样存在）：
  - `02_types.ml`：5 处 `Warning 26 unused-var`（`c_newline` / `u` / `p` / `x` / `y`）→ 改成真的打印出来
  - `12_modules.ml`：`let (|>) = Stdlib.(|>)` 未使用 → 改成真的用 `|>` 串起来
  - `19_testing.ml`：12 处 `run_check` 返回值没人用 → 汇总成一行统计打印
  - `20_records.ml`：2 处 `Warning 23 useless-record-with`（`with` 里列全了字段）→
    point 只有两个字段，改写成完整记录；多字段更新改用三字段记录演示
- 反向验证：造 6 个坏样例（缺结束标记 / 写 stderr / 退出码 1 /
  stdout 含 NUL+ESC / 编译有告警 / 退出码 0 但无输出），
  两个入口**全部报 FAIL 且理由正确**，验完删除
