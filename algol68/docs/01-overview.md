# 01 · 全景与工具链

> 面向**会编程（任意语言背景）、初学 Algol 68** 的读者。本章不带示例，先把"Algol 68 是什么、
> a68g 怎么跑、本教程怎么验证"讲透——后面每章都建立在这里的约定上。

## 1. Algol 68 家族简史（五分钟版）

| 年代 | 事件 | 意义 |
|---|---|---|
| 1958/1960 | ALGOL 58 / **ALGOL 60** | 第一个有形式语法（BNF）定义的命令式语言；学术界的事实标准，但缺 I/O、字符串、可变数组 |
| 1962–1968 | IFIP WG 2.1 设计后继语言 | 目标：一门**正交、强类型、自洽**的通用语言，把 ALGOL 60 的缺口一次补齐 |
| 1968 | **"Final Draft" Report** | 用 van Wijngaarden 的**两层文法（W-文法）**定义语言——表达力极强，也以晦涩著称 |
| 1968 | 著名的**分裂** | Wirth / Hoare / Dijkstra 等反对新设计的复杂度，退出另起炉灶（→ ALGOL W → Pascal 一脉）；Algol 68 自此走"叫好不叫座"的路 |
| 1975 | **Revised Report**（修订报告） | 简化、纠错后的权威定义；1976/77 出第二版。**a68g 实现的就是修订报告** |
| 2001– | **Algol 68 Genie（a68g）** | Marcel van der Veer 启动的开源实现，GPL；公认最完整的 Algol 68 实现之一 |
| 今天 | **a68g 3.13.3** | 解释器 + C 后端编译器二合一，带并行、GSL 数值库、ncurses、curl |

**为什么 2026 年还值得碰它**：Algol 68 是**语言设计史上的"理想主义高峰"**。它在上世纪 60 年代
就把许多今天才被视为理所当然的特性做成了一等公民——正交的类型系统（**mode**）、**一切皆表达式**、
**用户自定义运算符与优先级**、**内建并行**（`PAR` / `SEMA`）、**垃圾回收**、**可变长数组**
（`FLEX`）、**联合类型**（`UNION`）、**引用与堆**（`REF` / `HEAP`）、**格式驱动的 transput**。
读它，是读"如果没有 1968 年那场分裂、命令式语言本可以长成什么样"。

**它的脾气**：语法极其规整但**反直觉**——没有"语句"与"表达式"之分（统称 **unit**，都产值），
关键字靠**大小写（上戳）**而非保留字区分，声明可写在块内任何位置，运算符可自定义且**优先级是语言
的一部分**。它几乎没有现代生态（无包管理器、标准库就是 prelude），学它的目的是**理解正交语言
设计的范式、读懂这门"设计师的语言"**，不是拿它写新项目。

## 2. Algol 68 Genie：既是解释器也是编译器

a68g 是本教程使用的开源实现，特点：

- **两种执行形态，一套源码**：
  - **解释器**（默认）：直接读 `.a68` 源码、边解析边执行——开发期最快，运行期带全套检查。
  - **C 后端编译**（`-O0..-O3`，常用 `-O2`）：把源码翻译成 C，再交给系统 C 编译器（本机是
    `clang`）编成原生代码运行——这是真实"出货"形态。
    **Windows 例外**：官方 Windows 构建未实现 C 后端——`-O2`/`--compile`/`--optimise` 一律报
    `not implemented for this platform`，Windows 上只有解释执行一种形态（详见 §9）。
- **修订报告的完整实现**：`port info` 的原话——"an implementation of Algol 68 as defined by the
  Revised Report. It ranks among the most complete implementations of the language."
- **可选大依赖**：GSL（GNU Scientific Library，数值）、MPFR/GMP（高精度）、ncurses（终端）、
  readline、curl。本教程的基础章节不依赖它们。

```text
.a68 源码 ──┬──(默认)──▶ a68g 解释器直接执行（带全套运行时检查）
            │
            └──(-O2)────▶ 翻译成 .c ──clang──▶ 原生可执行 ──▶ 运行
```

> **本教程的核心保证**：同一份源码，**解释执行**与**编译执行**两条通道的 stdout 必须
> **逐字节一致**。任何依赖未定义行为、或"优化改变了语义"的代码，都会在这个比对里当场暴露。

## 3. 上戳（stropping）：关键字靠大小写区分

Algol 68 报告用**粗体**排印关键字（**begin**、**int**、**proc**……）。纯文本打不出粗体，于是有了
"stropping（上戳）"约定：用某种记法把关键字标出来。a68g 支持三种，由开关切换：

| 模式 | 开关 | 写法 | 本教程 |
|---|---|---|---|
| **上戳（upper-stropping）** | 默认 | 关键字**全大写**：`BEGIN` `END` `INT` `PROC` `IF` `THEN` | ✅ 统一用这个 |
| 粗体上戳（bold） | `--boldstropping` | 用某种粗体标记符包住关键字 | — |
| 引号上戳（quote） | `--quotestropping` | `'begin'` 这样加引号 | — |

因此本教程里：**语言关键字全大写**，**自起的标识符全小写**（`sum`、`name`、`assert`）。大小写
本身就是"哪个是保留词"的标记——实测小写的 `begin ... end` 不是关键字，会直接 `syntax error`。

源文件统一用 `.a68` 扩展名（a68g 也接受 `.a68g` / `.algol68`）。

## 4. 编译/运行模型：一条命令到底

```bash
a68g prog.a68                 # 默认：解释执行
a68g -O2 prog.a68             # 编译到 C 后端（优化）再运行
a68g --check prog.a68         # 只做语法/语义检查，不运行（--norun 同义）
a68g --compile prog.a68       # 只编译，不运行
```

**几个关键点**：

- **没有独立的"编译再运行"两步**：`a68g -O2 prog.a68` 一条命令完成"翻译 C → clang 编译 → 运行"。
- **编译期诊断与运行期错误走同一个 stderr**：告警（`--warnings`）、提示（`--notices`）、断言失败、
  运行时错误，全都吐到 stderr——本教程据此判"stderr 必须为空"。
- **诊断开关**：`--warnings`（告警）、`--notices`（提示，如"标签未使用""遮蔽 prelude 名"）、
  `--pedantic`（= `--notices --warnings --portcheck`，最严）、`--quiet`（全压）。
- **断言开关**：`--assertions`（默认开）/ `--noassertions`（关掉内建 `ASSERT`）。

## 5. 程序骨架：一个 BEGIN...END 就是整个程序

Algol 68 没有 COBOL 的"四大部"，也没有 C 的 `main`。一个程序就是**一个封闭子句
（closed clause）**——`BEGIN ... END` 括起来的一段，声明与语句按顺序混排，用分号 `;` 分隔：

```algol68
BEGIN
  INT sum := 1 + 2;                       # 声明并初始化，可出现在任何位置 #
  print(("1 + 2 = ", whole(sum, 0), new line));
  print(("==== 结束 ====", new line))      # 最后一条语句与 END 之间【不写】分号 #
END
```

铁律（详见 [02 章](02-hello.md)）：

1. `BEGIN ... END` 括出一个作用域，也是整个程序的边界。
2. 语句之间用 `;`，但**最后一条与 `END` 之间不写 `;`**（多写会触发 `skipped superfluous semi-symbol` 告警）。
3. 注释用 `#` 开、`#` 闭，且**可嵌套**——注释体内不能再出现裸 `#`。
4. 每个 unit 都产值；`print` 一个裸 `INT` 会按默认宽度**右对齐、带符号**输出，要紧凑用 `whole(n, 0)`。

## 6. 工具链安装（本机布局）

本教程实测机器有两台。

macOS（MacPorts）：

| 组件 | 路径 / 值 | 说明 |
|---|---|---|
| a68g 3.13.3 | `/opt/local/bin/a68g` | 解释器 + C 后端编译器 |
| MacPorts 端口 | `algol68g @3.13.3_0` | `port install algol68g` |
| 构建级别 | `2.1212 clang Aug 27 2026` | `a68g --version` 可见 |
| 特性 | plugin-compilation / parallel-clause / curl 8.7.1 / GSL 2.8 / ncurses 6.6 | 同上 |
| 依赖库 | gmp、gsl、mpfr、ncurses、readline | `port info algol68g` |
| C 后端 | `/usr/bin/clang`（Apple LLVM） | `-O2` 翻译出的 C 由它编译 |

Windows 11（scoop）：

| 组件 | 路径 / 值 | 说明 |
|---|---|---|
| a68g 3.13.3 | `%SCOOP%\apps\algol68g\current\bin\a68g.exe`（scoop shim 在 PATH） | `scoop install algol68g` |
| C 后端 | **无** | `-O2`/`--compile`/`--optimise` 报 `not implemented for this platform` |
| parallel-clause | **未编入** | 含 `PAR` 的源码直接 syntax error（第 17 章示例跳过） |
| INT 宽度 | **64 位**（`max int` = 9223372036854775807） | macOS 构建为 32 位——宽度随构建变，勿硬编码 |

新机器安装：

- **macOS**：`sudo port install algol68g`（MacPorts）。
- **Linux**：发行版包（Debian/Ubuntu 包名是 `algol68g`：`sudo apt install algol68g`）或从官网源码构建。
- **Windows**：`scoop install algol68g`（或官网下载构建）；注意官方构建**无 C 后端、无
  parallel-clause、INT 为 64 位**（三大缺口见 §9），验证脚本会自动探测并跳过受影响项。
- 官方主页：<https://algol68genie.nl/>。

验证安装：

```bash
a68g --version       # 应显示 Algol 68 Genie 3.13.3
a68g --help          # 查看全部开关（诊断/优化/断言/stropping…）
```

脚本按 **环境变量 `A68G` → 固定路径（`/opt/local/bin/a68g` 等）→ PATH** 顺序探测，不硬编码。

## 7. a68g 常用开关总览

```text
执行形态
  （无）        解释执行（默认）
  -O0/-O1/-O2/-O3   编译到 C 后端并运行，把优化级传给后端 C 编译器
  --check / --norun 只做语法/语义检查，不运行
  --compile         只编译，不运行
  --run             覆盖 --check/--norun
  --rerun           用已编译好的代码再跑一次
诊断（本教程 check 通道全开）
  --warnings / --nowarnings     告警
  --notices  / --nonotices      提示（未使用标签、遮蔽 prelude 名等）
  --pedantic                    = --notices --warnings --portcheck（最严）
  --portcheck                   可移植性告警
  --quiet                       压掉告警与提示
  --strict                      关闭大多数 Algol 68 语法扩展
断言与运行时
  --assertions / --noassertions 内建 ASSERT 的开/关（默认开）
  --backtrace                   运行时错误打印栈回溯
  --lenient                     允许 infinity/NaN 传播
  --timelimit "n"               n 秒后中断解释器
资源上限
  --heap/--stack/--frame/--handles "n"   调各内存区大小
stropping
  --boldstropping / --quotestropping     切换上戳模式（默认上戳=关键字大写）
```

本教程的两个验证通道：

```text
check 通道：  a68g --warnings --notices prog.a68   （解释器，告警+提示零容忍是纪律）
release 通道：a68g -O2 prog.a68                    （C 后端，真实出货形态）
两通道输出必须逐字节一致——任何差异都是"优化改变了语义"的味道，要查
（Windows 构建无 C 后端：脚本探针检测后 release 自动 [SKIP]，仅以 check 判定——见 §9）
```

## 8. 本教程的验证方法论（贯穿全部示例）

| 层 | 手段 | 覆盖 |
|---|---|---|
| 编译/运行 | a68g 双通道（`--warnings --notices` / `-O2`） | 语法语义正确 + 告警/提示零容忍 |
| 运行 | 退出码 0 + stderr 空 + stdout 无控制字符（TAB/LF/CR 除外）+ 含结束标记 | 程序真跑通了 |
| 断言 | 自定义 `assert` 把 FAIL 写进 `stand error`；内建 `ASSERT` 守硬不变量 | 关键数值/行为正确 |
| 一致性 | check 与 release 两通道 stdout 逐字节 `cmp` | 解释器与编译后端语义吻合 |

> Windows 等无 C 后端的构建上，"编译/运行"与"一致性"两层自动收缩为单通道判定——脚本
> 探针确认后跳过 release 通道（计入「平台跳过」，不计失败）。

**断言习惯（全书一致）**：a68g **没有"以整数退出码结束"的标准设施**（不像 COBOL 的
`STOP RUN RETURNING n`）——退出码 0 只表示"无运行时错误"。所以本教程统一用——

```algol68
  INT fails := 0;
  PROC assert = (BOOL cond, STRING msg) VOID:
    IF NOT cond THEN put(stand error, ("FAIL: ", msg, new line)); fails +:= 1 FI;
  ...
  print(("==== NN 结束 ====", new line));      # 结束标记，供脚本 grep，证明跑到了尾 #
  IF fails > 0 THEN print(("自检失败 ", fails, " 项", new line))
  ELSE print(("自检全部通过", new line)) FI
```

失败信号靠 **stderr 非空**被验证脚本捕获（CI 判"stderr 为空"）。另有一道硬保险：内建
`ASSERT (BOOL)`，条件为假 → 运行期错误 `false assertion`、**退出码 1**——这是 a68g 里唯一
能"以非零退出码 fail-fast"的机制，详见 [18 章](18-testing.md)。

## 9. 平台专属坑：macOS 链接缺 `-syslibroot`；Windows 三大缺口

### 9.1 macOS：`a68g -O2` 的链接步骤缺 `-syslibroot`

本机（macOS）实测：`a68g -O2` 把源码翻成 `.c` → `.o` 后，用

```text
ld -export_dynamic -undefined dynamic_lookup -lSystem -o x.so x.o
```

链接，但**没有 `-syslibroot`**，于是在较新的 macOS 上报 `ld: library 'System' not found`，
release 通道直接失败。

对策（本教程 `run-all.sh` 已内置）：造一个 `ld` 垫片放进 `PATH` 最前，把真实的 `/usr/bin/ld`
补上 `-syslibroot`：

```bash
# build/.shim/ld
#!/bin/sh
exec /usr/bin/ld -syslibroot "$(xcrun --show-sdk-path)" "$@"
```

> 垫片只在 **Darwin 且能取到 SDK** 时安装；Linux 上 a68g 的链接命令本就正常，垫片不触发。
> 另外 `run-all.sh` 开头会把 locale 切到某个 UTF-8（`C.UTF-8`/`en_US.UTF-8`）：在 `C` locale 下，
> bash 会把紧邻全角标点的 `$变量`（如 `"$why；"`）误分词，触发 `set -u` 报"未绑定变量"——这是
> 写验证脚本时踩到的真实坑。

### 9.2 Windows：官方构建的三大缺口（scoop algol68g 3.13.3 实测）★

1. **无 C 后端**：`-O2` / `--compile` / `--optimise` 一律
   `a68g: scanner error: at option "-O2", not implemented for this platform`。
   Windows 上只有解释执行一种形态。验证脚本（`build.ps1` 与 Git Bash 下的 `run-all.sh`）开头
   用微型探针（跑一次 `a68g -O2` 一行程序）确认后，release 通道自动 `[SKIP]`，仅以 check
   通道判定，计入「平台跳过」而非失败。想要编译执行：用 Linux/macOS 构建，或自行编译
   a68g 源码启用插件编译。
2. **未编入 parallel-clause**：含 `PAR` 的源码在**语法层**就被拒——
   `a68g: syntax error: 1: interpreter was built without parallel-clause support`，
   连解释器都跑不起来（并行是语法特性，不是运行时库）。17 章示例在 Windows 上经探针
   （跑 `PAR (SKIP)`）确认后自动跳过；要跑并行章节需 macOS/Linux 构建。
3. **INT 是 64 位**：`max int` = `9223372036854775807`，而 macOS MacPorts 构建是 32 位
   `2147483647`——**INT 宽度随构建而变，代码里别硬编码**。第 04 章示例已把断言改为
   `assert(max int >= 2147483647, ...)`。

另两个同机实测的小坑：

- `a68g --strict`（关闭语法扩展）把 `DOWNTO` 直接判 `syntax error`、给 `stand error` 报
  `not portable` notice——本教程示例按 a68g 常规模式写，不受影响，但想拿 `--strict` 当
  额外验证通道就行不通。
- pwsh 的 `Get-ChildItem -Path 裸目录 -Include '*.txt'` **匹配不到任何文件**（`-Include`
  须配 `-Path "$dir\*"` 或 `-Recurse`）——曾让 `build.ps1` 的数据文件清理静默失效，第二轮
  起触发 `establish` 的 `file exists` 中止。

## 10. 学习路线

- **语言篇（02–13）**：顺序读，每章"读讲解 → 跑示例 → 改代码再跑"。
  [03 模式](03-modes.md)、[07 字符串](07-strings.md)、[13 闭包与作用域规则](13-closures.md)
  是 Algol 68 特有深水区，值得两遍。
- **系统篇（14–19）**：[14 transput 文件](14-transput.md)、[15 格式化](15-formats.md)、
  [16 异常与事件](16-exceptions.md)、[17 并行](17-parallel.md)、[18 测试](18-testing.md)、
  [19 综合实战](19-capstone.md)。
- **速查**：[`CHEATSheet.md`](../CHEATSheet.md)——语法速查 + 全部实测坑位索引
  （每章"坑位清单"的汇总，分类索引见 [20 章](20-pitfalls.md)）。

把 `run-all.sh`（一条命令回归全部示例）搬走，你的下一个 Algol 68 项目就有 CI 了。

## 11. 坑位清单（工具链实测）

1. **关键字靠上戳（大写）区分**：`BEGIN`/`END`/`INT`/`PROC` 必须全大写；小写的 `begin` 不是关键字 → `syntax error`。
2. **`END` 前多写 `;`**：触发 `skipped superfluous semi-symbol` 告警，check 通道 stderr 非空 → 判 FAIL。
3. **`print` 裸 `INT` 是宽格式**：右对齐、带 `+`/`-` 号；要紧凑输出先 `whole(n, 0)`。
4. **没有整数退出码设施**：断言失败要自己写 `stand error`；退出码 0 只代表无运行时错误（唯一例外是内建 `ASSERT` 失败 → 退出码 1）。
5. **macOS + `a68g -O2` 链接缺 `-syslibroot`**：`ld: library 'System' not found`；用 `ld` 垫片修复（见 §9.1）。
6. **`C` locale 下的 bash 误分词**：紧邻全角标点的 `$var` 被吞；脚本开头切 UTF-8 locale，并给紧邻 CJK 标点的变量加花括号 `${var}`。
7. **别和 prelude 撞名**：把变量命名为 `pi`/`e`/`ln`/`eof`/`lock` 等会遮蔽 prelude 声明，触发 notice → check 通道 stderr 非空。
8. **Windows 构建无 C 后端**：`-O2`/`--compile`/`--optimise` 报 `not implemented for this platform`；脚本探针检测后 release 通道自动跳过（见 §9.2）。
9. **Windows 构建未编入 parallel-clause**：含 `PAR` 的源码语法层直接报错；17 章示例自动跳过（见 §9.2）。
10. **INT 宽度随构建而变**：macOS 构建 32 位 / Windows 构建 64 位；勿硬编码 `max int`（见第 04 章）。

---
下一章：[02 第一个程序](02-hello.md) ｜ 返回：[README](../README.md)
