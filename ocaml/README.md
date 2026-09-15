# OCaml 教程与示例

OCaml 入门到进阶，配套 22 个可运行示例，在 OCaml 顶层解释器（`ocaml`）和字节码编译器（`ocamlc`）上验证通过。

这里不是「语法速览」。模块系统（`module` / `signature` / `functor` / `include`）、多态变体、首类模块、`ref` 与可变状态、异常与模式匹配、以及标准库的惯用写法，都在示例里实打实跑过。

## 目录结构

```
ocaml/
├── README.md                 本文件
├── OCaml编程指南.md          教程正文（25 章）
├── build.ps1                 PowerShell 构建/验证入口
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
    ├── 12_modules.ml             module / signature、透明约束、open、include
    ├── 13_functors.ml            functor、参数化模块、sharing constraint
    ├── 14_mutable.ml             ref / Array / Hashtbl、物理相等 vs 结构相等
    ├── 15_algorithms.ml          插入/归并/快速排序、二分查找、筛法、记忆化
    ├── 16_numeric.ml             二分法/牛顿法、数值积分、克拉默法则、插值
    ├── 17_parsing.ml             词法分析 + 递归下降求值器、词频统计
    ├── 18_io.ml                  标准 I/O、文件读写、Printf、目录操作
    ├── 19_testing.ml             断言框架、异常断言、属性测试、测试报告
    ├── 20_records.ml             记录高级用法、对象（object）、类（class）
    ├── 21_streams_seq.ml         Seq 惰性序列、Stream 流、管道式数据处理
    └── 22_project.ml             综合实战：成绩 CSV 分析与报告
```

## 工具链

| 工具 | 路径候选 | 定位 |
|---|---|---|
| `ocaml` | `/usr/local/bin/ocaml`、`/opt/local/bin/ocaml`、`/usr/bin/ocaml` | 顶层解释器（REPL），交互式调试与快速验证 |
| `ocamlc` | `/usr/local/bin/ocamlc`、`/opt/local/bin/ocamlc`、`/usr/bin/ocamlc` | 字节码编译器，跨平台、编译快、便于验证 |
| `ocamlopt` | `/usr/local/bin/ocamlopt`、`/opt/local/bin/ocamlopt`、`/usr/bin/ocamlopt` | 原生代码编译器（可选），生成高性能本地可执行文件 |

验证安装：

```bash
ocaml -version           # 查看 OCaml 版本
ocamlc -version          # 查看字节码编译器版本
ocamlopt -version        # 查看原生编译器版本（如已安装）
```

## 构建与验证

使用 `build.ps1` 调用 `ocamlc` 编译示例，输出到 `build/` 目录。

| 命令 | 说明 |
|---|---|
| `ocamlc -o build/NN examples/NN.ml` | 字节码编译单个示例，生成字节码可执行文件 |
| `ocaml examples/NN.ml` | 顶层解释器直接运行 |
| `ocamlopt -o build/NN.opt examples/NN.ml` | 原生编译（可选） |

PowerShell：

```powershell
cd /Users/xulun/code/programming/ocaml
pwsh ./build.ps1 -All                 # 编译全部 22 个示例
pwsh ./build.ps1 -File 01_basics.ml   # 编译单个示例
pwsh ./build.ps1 -File 01             # 只写编号也行
pwsh ./build.ps1 -Clean               # 清理 build 目录
```

### 判定标准

1. **退出码为 0** —— `ocamlc` 编译成功
2. **生成字节码可执行文件** —— `build/` 目录下存在对应输出
3. **运行时退出码为 0** —— 执行字节码文件无异常
4. **stdout 里出现结束标记** `==== NN jieshu ====` —— 证明程序完整执行到结尾

失败时 `build.ps1` 返回退出码 1，可以直接拿去做回归。

> 关于中文：本教程的字符串字面量里只写 ASCII，中文全部放注释。这样可以确保代码在所有 OCaml 实现和环境中都能正确编译运行。需要输出中文时可以通过 `Printf` 或字符串拼接的方式，但本示例集为了可移植性统一使用英文输出。

## 各章索引

| 章 | 主题 | 关键内容 |
|---|---|---|
| 1 | 认识 OCaml | OCaml 的定位、ML 家族谱系、函数式 + 命令式 + 面向对象三合一、工具链概览 |
| 2 | 工具链与运行方式 | `ocaml` 顶层 / `ocamlc` 字节码 / `ocamlopt` 原生三种运行方式、utop 简介、opam 与 dune |
| 3 | 程序结构与求值 | `let` 绑定、`let ... in` 局部绑定、类型推断、类型标注、注释、求值顺序（示例 01） |
| 4 | 类型系统 | `int` / `float` / `bool` / `char` / `string` / `unit`、类型别名 `type`、多态类型变量、值限制（示例 02） |
| 5 | 表达式与运算符 | 优先级、`~-` 取负、`/` 与 `/.` 整数/浮点除法、`&&` / `||` 短路、`if` 是表达式（示例 03） |
| 6 | 元组与记录 | 元组解构、记录定义与字段访问、`mutable` 可变字段、`with` 复制更新、嵌套记录（示例 04） |
| 7 | 模式匹配 | `match` / `function`、通配 `_`、字面量、构造子、`as` 别名、`when` 守卫、嵌套模式、穷尽性检查（示例 05） |
| 8 | 列表与高阶列表函数 | `::` 与 `@`、`List.map` / `List.filter`、`fold_left` 与 `fold_right` 的区别、`List.init`、`List.partition`（示例 06） |
| 9 | 变体类型 | `type t = ...` 代数数据类型、参数化构造子、递归类型（二叉树、表达式）、多态变体 `` `A ``（示例 07） |
| 10 | 字符串与字符 | `String.length` / `String.get` / `String.sub` / `String.concat`、字符串不可变、`Printf.printf` 格式化、`Bytes` 可变字符串（示例 08） |
| 11 | 递归与尾递归 | 尾递归与累积器、`fold_left` 的等价改写、互递归 `and`、Ackermann 函数、汉诺塔（示例 09） |
| 12 | 异常 | `raise` / `try ... with`、自定义异常 `exception`、异常参数、`exn` 可扩展变体本质、异常 vs `option`（示例 10） |
| 13 | 高阶函数与闭包 | 柯里化与偏应用、闭包与独立计数器、函数组合 `@@` / `|>` 管道运算符、函数列表（示例 11） |
| 14 | 模块与签名 | `module` / `module type`、透明约束 `:`、`open` 与命名空间、`include`、一个签名两套实现（示例 12） |
| 15 | Functor（函子） | `functor (X : S) -> struct ... end`、多参数 functor、`sharing` 约束、结果签名约束、Set/Map 原理（示例 13） |
| 16 | 不透明约束与抽象数据类型 | `:` vs `:>`、抽象数据类型、不变量保护、隐藏辅助函数、functor + 不透明约束（见第 15 章 + 第 16 章指南） |
| 17 | 模块系统进阶 | 嵌套模块、`include` 多重继承、局部 open `let open ... in`、模块别名、`module type of`（见第 17 章指南） |
| 18 | 可变状态 | `ref` / `!` / `:=`、`while` / `for` 循环、`Array` 数组、`Hashtbl` 哈希表、`Buffer`、物理相等 `==` vs 结构相等 `=`（示例 14） |
| 19 | 排序与经典算法 | 插入/归并/快速排序互相校验、二分查找、埃氏筛法、`gcd` / `lcm`、记忆化斐波那契（示例 15） |
| 20 | 数值计算 | 二分法与牛顿法求根、梯形与辛普森积分、克拉默法则、拉格朗日插值、浮点数三大坑（示例 16） |
| 21 | 解析：词法分析与递归下降 | 手写词法器（`token` 类型 + 扫描器）、递归下降求值器、错误捕获与报告、词频统计（示例 17） |
| 22 | 输入输出与文件 | `print_endline` / `print_string`、`Printf.printf` 格式化、文件读写 `open_in` / `open_out`、目录操作 `Sys`（示例 18） |
| 23 | 测试与断言 | 断言框架实现、各类型断言、浮点数 epsilon 比较、异常断言、测试套件与报告（示例 19） |
| 24 | 记录、对象与类 | 记录高级用法、函数字段、`object` 对象、`class` 类简介、结构继承（示例 20） |
| 25 | 流与序列 + 综合实战 | `Seq` 惰性序列、`Stream` 流、管道式数据处理（示例 21）；成绩 CSV 分析综合项目（示例 22） |

## 当前状态

22 个示例在 `ocamlc` 字节码编译器上验证通过，顶层解释器 `ocaml` 可直接加载运行。
