# Common Lisp 教程（SBCL + CLISP 双实现）

面向**会编程、看得懂 S 表达式、没系统写过 Lisp** 的读者：从 REPL 讲到
CLOS、宏、条件系统，再到线程/FFI/性能的 SBCL 专属扩展。**语言主线与实现解耦**
——第 02–20 章及 22/27 章的每个示例同时跑在 **SBCL 和 GNU CLISP** 上，
两个通道的 stdout **逐字节一致**；SBCL 扩展（21/23–26 章）单独成章。

> 核心方法论：**可移植性不是背出来的，是 diff 出来的**。本目录的验证脚本
> 对每个双通道示例执行跨实现逐字节比对，27 条实测差异全部记录在
> [22 章](docs/22-implementations.md)与 [CHEATSheet](CHEATSheet.md)。

## 目录结构

```text
commonlisp/
├── README.md        本文件
├── docs/            27 章教程（01 → 27 顺序阅读）
├── examples/        26 个示例目录（章号 = 目录号，各含 main.lisp）
├── CHEATSheet.md    语法速查 + 27 条双实现差异 + 报错速查
├── build.ps1        统一验证脚本（PowerShell 7 / pwsh）
├── run-all.sh       同一套验证的 bash 版（macOS/Linux）
└── verify-guide.py  核查 docs/ 里 `; =>` 断言的脚本
```

## 章节索引

### 语言核心（双实现通道）

| 章 | 主题 | 示例 |
|---|---|---|
| [01 全景](docs/01-overview.md) | ANSI 标准、实现生态、双实现策略 | — |
| [02 第一个程序](docs/02-hello.md) | REPL、脚本、双实现跑法、#+/#- | `02_hello` |
| [03 求值模型](docs/03-evaluation.md) | 读入与求值分离、quote、特殊形式 | `03_evaluation` |
| [04 数字](docs/04-numbers.md) | 数值塔、有理数、浮点传染差异 | `04_numbers` |
| [05 字符与字符串](docs/05-strings.md) | 字符向量、码点、编码 | `05_strings` |
| [06 符号与包](docs/06-symbols-packages.md) | intern、包、可见性、包锁 | `06_symbols` |
| [07 列表与相等](docs/07-lists.md) | cons、破坏性操作、五种相等 | `07_lists` |
| [08 数组与序列](docs/08-arrays-sequences.md) | 向量、fill-pointer、sort/reduce | `08_sequences` |
| [09 哈希表与结构体](docs/09-hash-structs.md) | :test 的坑、遍历排序、defstruct | `09_hash` |
| [10 变量与作用域](docs/10-variables.md) | defvar/defparameter、词法 vs 动态 | `10_variables` |
| [11 函数](docs/11-functions.md) | 参数四件套、多值、闭包、尾调用 | `11_functions` |
| [12 控制流与迭代](docs/12-control.md) | cond/case、loop 全姿势、块与跳转 | `12_control` |
| [13 类型系统](docs/13-types.md) | typep、deftype、check-type/the | `13_types` |
| [14 宏 I](docs/14-macros.md) | defmacro、反引号、macroexpand | `14_macros` |
| [15 宏 II](docs/15-macros-advanced.md) | 捕获、gensym、once-only、eval-when | `15_macros_adv` |
| [16 format](docs/16-format.md) | 指令全家桶与三大名坑 | `16_format` |
| [17 流与文件](docs/17-io.md) | 读写三法、路径名、目录、rename 坑 | `17_io` |
| [18 条件系统](docs/18-conditions.md) | handler-bind、restart、检测与策略分离 | `18_conditions` |
| [19 CLOS I](docs/19-clos.md) | 类、泛型函数、多分派、继承 | `19_clos` |
| [20 CLOS II](docs/20-clos-advanced.md) | 方法组合、eql 特化、非标准组合、MOP | `20_clos_adv` |

### 工程与实现（22 双通道，21/23–26 SBCL 专属）

| 章 | 主题 | 示例 | 通道 |
|---|---|---|---|
| [21 工程化](docs/21-engineering.md) | ASDF 真跑、迷你测试框架、Quicklisp、部署 | `21_asdf` | sbcl |
| [22 实现对比与可移植性](docs/22-implementations.md) | 27 条差异总账 + 五条军规 | `22_portability` | both |
| [23 SBCL 扩展 I](docs/23-sbcl-extensions.md) | run-program、GC、编译器、映像、CAS | `23_sbcl_ext` | sbcl |
| [24 SBCL 扩展 II：线程](docs/24-sbcl-threads.md) | 锁、条件变量、信号量、线程池 | `24_sbcl_threads` | sbcl |
| [25 SBCL 扩展 III：FFI](docs/25-sbcl-ffi.md) | sb-alien 调 C、类型映射、CFFI | `25_sbcl_ffi` | sbcl |
| [26 性能优化](docs/26-performance.md) | 声明、optimize、profile、disassemble | `26_perf` | sbcl |
| [27 实战：迷你 Lisp 解释器](docs/27-minilisp.md) | 环境/闭包/递归 + 40 断言 | `27_minilisp` | both |

## 工具链

| 通道 | 本教程实测 | 安装 |
|---|---|---|
| SBCL | 2.6.8（Linux/WSL2；2.6.7 macOS 亦验证过） | `pacman -S sbcl` / `port install sbcl` / `scoop install sbcl` |
| CLISP | 2.49.95（Linux/WSL2） | `pacman -S clisp` / `port install clisp` |

CLISP 启动记得 `-E UTF-8`（默认编码跟 locale 走，ASCII 终端下中文直接报错）——
验证脚本已内置。

## 验证命令

```bash
cd commonlisp
./run-all.sh                    # 全部 26 个示例 × 双通道（47 单元）
./run-all.sh 12                 # 只跑 12 章
SBCL=/path/sbcl CLISP=/path/clisp ./run-all.sh
```

```powershell
pwsh ./build.ps1 -All           # Windows / 有 pwsh 的平台
pwsh ./build.ps1 -Example 12_control
pwsh ./build.ps1 -Clean
```

**判定标准**：每通道四条（退出码 0 + stderr 空 + stdout 无多余控制字符 +
结束标记 `==== NN 结束 ====`）；`channel: both` 的示例加第五条
**SBCL 与 CLISP 的 stdout 逐字节一致**。两个入口判定逻辑一致；
**不要并行跑两份**（共用 build/ 产物目录）。

教程正文里所有 `; =>` 断言由 `verify-guide.py` 逐条在 SBCL 上回跑核验：

```bash
python3 verify-guide.py         # 核验 docs/*.md 全部代码块
```

## 示例怎么读

每个示例文件头部有通道声明：

```lisp
;; channel: both   → SBCL + CLISP 双通道，输出必须逐字节一致
;; channel: sbcl   → 仅 SBCL（ASDF/线程/FFI/性能章）
```

结尾的 `==== NN 结束 ====` 是「我完整跑完了」的标记。改代码后重跑：

```bash
./run-all.sh 04                 # 章号 = 目录号
```

## 相关教程

Lisp 家族对照：[clojure](../clojure/README.md)（JVM 系 Lisp）、
[emacs](../emacs/README.md)（Elisp）；同为标准稳定系函数语言的
[haskell](../haskell/README.md)；速查见 [CHEATSheet.md](CHEATSheet.md)。
