# OCaml 教程与示例

OCaml 入门到进阶，配套 **26 个可运行示例**，教程正文 **31 章**。
全部示例在字节码编译器（`ocamlc`）、原生编译器（`ocamlopt`）与顶层
解释器（`ocaml`）三种方式下验证通过；验证环境：

- **Windows 11 + MSYS2 UCRT64，OCaml 5.4.1**（26/26 字节码 + 25/25 原生全绿，
  含运行与结束标记核对）
- macOS / Linux 同源码可直接编译（涉及 `Unix` 模块的示例需链接 unix，
  `build.ps1` 已内置依赖表）

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
| `ocaml` | `<msys2>\ucrt64\bin\ocaml.exe` | `/usr/local/bin`、`/opt/homebrew/bin`、`/usr/bin` | 顶层解释器（REPL）/ 脚本执行 |
| `ocamlc` | 同上目录 | 同上 | 字节码编译器，编译快、便于验证 |
| `ocamlopt` | 同上目录（需 flexdll 包） | 同上 | 原生编译器，生成高性能可执行文件 |
| `ocamllex` | 同上目录 | 同上 | 词法分析器生成器（示例 26） |

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

使用 `build.ps1` 编译并**实际运行**每个示例（不只是编译），
输出到 `build/` 目录。

| 命令 | 说明 |
|---|---|
| `pwsh ./build.ps1 -All` | 编译 + 运行全部示例（字节码） |
| `pwsh ./build.ps1 -All -Native` | 追加 ocamlopt 原生编译与运行 |
| `pwsh ./build.ps1 -All -NoRun` | 只编译不运行 |
| `pwsh ./build.ps1 -File 01` | 编译单个示例（写编号或全名均可） |
| `pwsh ./build.ps1 -File 26` | ocamllex 组合示例（两段式构建） |
| `pwsh ./build.ps1 -Clean` | 清理 build 目录 |

### 判定标准

1. **编译退出码为 0** —— `ocamlc` / `ocamlopt` 编译成功
2. **运行退出码为 0** —— 执行产物无异常
3. **stdout 出现结束标记** `==== NN jieshu ====` —— 程序完整执行到结尾
4. 依赖 `Unix` 模块的示例（15/18/21/22/25）自动链接 `unix.cma` / `unix.cmxa`

失败时 `build.ps1` 返回退出码 1，可以直接拿去做回归。

### 手工编译（等价命令）

```bash
ocaml -w -24 examples/01_basics.ml                                # 解释执行
ocamlc -w -24 -o build/01_basics examples/01_basics.ml            # 字节码
ocamlopt -w -24 -o build/01_basics_opt examples/01_basics.ml      # 原生
ocamlc -w -24 -I "$(ocamlc -where)/unix" unix.cma -o build/15_algorithms examples/15_algorithms.ml
```

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
  原生 25/25 全绿（编译 + 运行 + 结束标记三层判定）
- 初版 12–22 号示例存在与平台无关的结构性语法错误（顶层
  `let ... in`、缺 `;;`、无效 package type 等），已全部修复并
  计入第 31 章坑清单
