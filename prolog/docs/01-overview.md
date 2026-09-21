# 01 · Prolog 全景

> 对应示例：无（本章是地图；从 02 章起每章一个可独立运行的示例目录）

## 1.1 Prolog 是什么

Prolog 是一门**逻辑编程**语言：别的语言你写「怎么做」，Prolog 你写「什么是真的」。

```prolog
parent(tom, bob).
parent(bob, ann).

grandparent(X, Z) :- parent(X, Y), parent(Y, Z).
```

前两行是**事实**，第三行是**规则**，读作「若 X 是 Y 的亲代，且 Y 是 Z 的亲代，
则 X 是 Z 的祖辈」。写完这些，你就可以**提问**：

```prolog
?- grandparent(tom, ann).
true.

?- grandparent(tom, X).
X = ann.
```

三件事和命令式语言根本不同：

- **没有赋值，只有合一（unification）**。`X = 5` 不是「把 5 存进 X」，而是「让 X 和 5
  变成同一个东西」。X 已经有值时就退化成比较，`X = 5, X = 6` 直接失败（05 章）。
- **没有返回值，谓词只有「成功」或「失败」**。失败不是错误，是「这条路走不通」，
  系统自动回头试别的分支 —— 这就是**回溯**（06 章）。
- **没有循环，只有递归**。所有迭代都写成递归 + 累加器（09 章）。

再加一条：**没有类型声明**，但每一种数据都是同一个东西 —— **项（term）**。
原子、数字、变量、复合项全都是一等公民，程序本身也是项，所以程序能读写程序（12 章）。

与你会的语言对照：

| 你熟悉的 | Prolog 的不同 |
|---|---|
| `x = 5` 赋值 | `X = 5` 是合一；变量一旦绑定就不能改（要「改」就换一个新变量，或写进动态库） |
| `return` / `return None` | 谓词没有返回值：成功/失败是唯一输出，数据通过参数「带出来」 |
| `for` / `while` | 没有循环语句；用递归 + 回溯，或者 `forall/2`、`findall/3` 这类高阶谓词 |
| `if/else` 到处用 | 优先靠**同名谓词的多条子句**做分支，`(-> ;)` 只兜底（10 章） |
| `try/catch` 管一切 | 预期内的「没有」用失败表达，真的异常才 `throw`（20 章） |
| 函数式语言的可变量 | 只能靠动态数据库模拟（17 章），代价与风险要自己扛 |
| 类与继承 | 没有；靠命名前缀 + 模块（22 章）做组织 |

**适用范围**：Prolog 的甜区叫「符号推理」——自然语言解析、专家/规则系统、规划与调度、
约束求解、类型检查、数据库查询、程序分析、定理证明。它的弱项同样明确：数值密集型计算、
需要原地修改状态的算法、图形界面。别拿它写游戏引擎。

## 1.2 血统与生态

- **1972 年**诞生于法国马赛，Alain Colmerauer 与 Philippe Roussel（第一版用 Fortran
  实现），逻辑侧的奠基人是 Robert Kowalski。名字来自 **PRO**grammation en **LOG**ique。
- **ISO 标准**（1995，ISO/IEC 13211-1）把核心语法、内置谓词、错误项固定下来 ——
  这是本教程能「一份代码跑两套引擎」的底气。
- **两套主流实现**：**SWI-Prolog** 库最全、社区最活跃，是工程上的默认选择；
  **GNU Prolog** 体量极小、自带 FD 约束求解器，而且能把程序**编译成无运行时依赖的本地
  可执行文件**。两者对 ISO 的覆盖度不同，差异恰好是最有价值的教学材料。

本教程的核心主张：**用两套引擎交叉验证同一份代码**。不是在教你「怎么迁就某个实现」，
而是让你亲眼看到「哪些是语言本身，哪些只是某个实现的私货」。这条纪律会一直贯穿到 24 章。

## 1.3 本机工具链（实测）

| 工具 | 路径 | 版本 | 定位 |
|---|---|---|---|
| `swipl` | `/opt/local/bin/swipl` | SWI-Prolog 10.0.2 | 库最全，日常开发首选 |
| `gprolog` | `/opt/local/bin/gprolog` | GNU Prolog 1.5.0 | 体量小，自带 FD 约束求解器 |
| `gplc` | `/opt/local/bin/gplc` | 随 GNU Prolog 1.5.0 | 编成无依赖的本地可执行文件 |
| `pwsh` | `/opt/local/bin/pwsh` | PowerShell 7 | 跑 `build.ps1`（Windows/WSL 之外的备份入口） |

```text
$ swipl --version
SWI-Prolog version 10.0.2 for x86_64-darwin

$ gprolog --version
Prolog top-Level (GNU Prolog) 1.5.0

$ gplc --version
Prolog compiler (GNU Prolog) 1.5.0
```

安装（任选其一）：

```bash
sudo port install swi-prolog gprolog   # macOS MacPorts（本机即此）
brew install swi-prolog                # macOS Homebrew（GNU Prolog 需自行编译）
apt install swi-prolog gprolog         # Debian / Ubuntu
```

> **Windows 说明**：`swipl` 用 `scoop install swi-prolog` 即可（本仓库在 10.0.2
> x64-win64 上验证过）。**GNU Prolog 没有官方 Windows 构建**，`gprolog` / `gplc`
> 两条通道在 Windows 上不可用 —— `run-all.sh` 与 `build.ps1` 会自动跳过缺失的工具，
> 无需改动。所以 Windows 上你看到的是「单通道验证」，成果仍然有效，只是少了交叉比对。

## 1.4 三条运行通道

Prolog 没有 `main`。本教程把「跑一遍」脚本化，用三条通道各跑一遍：

**通道 1：SWI 解释执行**

```bash
swipl -Dencoding=utf8 -q -f examples/02_hello/02_hello.pl \
      -g "set_stream(user_output,encoding(utf8)),set_stream(user_error,encoding(utf8)),main" \
      -t halt
```

- `-q` 安静模式不打 banner；`-f FILE` 加载文件（不加 `-f` 会去读 `~/.swiplrc`）；
  `-g main` 加载完执行 `main/0`；`-t halt` 结束时保证退出。
- `-Dencoding=utf8` + `set_stream(...,encoding(utf8))` 是给 Windows 准备的：Windows 版
  swipl 默认按 ANSI 代码页（中文系统是 GBK）解码源文件和重定向流，UTF-8 中文示例会满屏
  `Illegal multibyte Sequence`。**两处都要补**：`-D` 管源文件解码，`set_stream` 管
  `user_output` 这个启动时就按本地编码打开的流。macOS/Linux 上两者等价无操作。

**通道 2：GNU 解释执行**

```bash
gprolog --consult-file examples/02_hello/02_hello.pl --entry-goal main
```

注意 GNU 会把编译信息（`compiling ... for byte code...`）打到 **stdout** 而不是 stderr
——这是本教程设计的第一个约束：判定不能依赖「stdout 只有程序输出」，而要靠**输出区间**。

**通道 3：gplc 编译成本地可执行文件**

```bash
{ echo ':- initialization(main).'; cat examples/02_hello/02_hello.pl; } > build/02.pl
cd build && gplc 02.pl -o 02.bin && ./02.bin
```

两个坑：

- **`gplc` 只在当前目录可靠工作**。源文件放子目录会因为找不到中间产物而链接失败。
  本仓库的做法是把源码拼一份到 `build/` 再编。
- **没有 `:- initialization(main).` 就不会自动执行**，产物会掉进交互式 toplevel 等键盘
  输入 —— 在脚本里就是**永久挂死**。所以 `run-all.sh` / `build.ps1` 必须重定向 stdin。

## 1.5 统一验证：六条判定

每个示例都要同时过六条（`run-all.sh` / `build.ps1` 双入口，结论必须一致）：

1. 退出码为 **0**；
2. **stderr 为空** —— 连一个 singleton 变量警告都不许有；
3. stdout 里同时出现 `==== NN 开始 ====` 与 `==== NN 结束 ====`;
4. 两条标记之间（下称**输出区间**）非空，且不含 CR / ESC 等控制字符；
5. 区间内不出现 `uncaught` / `command-line goal` / `异常:` / `运行失败` 等溃逃痕迹；
6. **三条通道抽出的输出区间逐字节相同**。

第 6 条是本教程最硬的写作纪律，值得解释。GNU 把 banner 与编译进度写进 stdout，SWI 与
GNU 的变量编号（`_A` vs `_G123`）、浮点打印位数、错误项形状又各不相同。所以约定：
**示例只打印「两套引擎必然一致」的内容，并用两条标记把它圈起来**；脚本抽取区间再逐字节
比对，banner 这类噪声自然被排除在外。这条纪律逼着你「断言性质」而不是「打印环境相关的
数字」，你看到的每一份输出在任何机器上都应当逐字节相同。

于是每个示例都长这个样子：

```prolog
main :-
    (   catch(run, E, (format(user_error, "*** 异常: ~q~n", [E]), halt(1)))
    ->  halt(0)
    ;   format(user_error, "*** run/0 失败~n", []),
        halt(1)
    ).

run :-
    format("==== 02 开始 ====~n", []),
    ...
    format("==== 02 结束 ====~n", []).
```

`halt(0)` 成功 / `halt(1)` 失败，CI 直接读退出码；出错原因写 stderr，stdout 保持干净。
**异常路径和失败路径分开处理**，两条路都能给出非零退出码 —— 少了 `halt`，程序跑完会掉进
toplevel 卡住。

跑起来：

```bash
./run-all.sh                  # 全部示例，只打印摘要
./run-all.sh -v               # 附每个通道抽出的输出区间
./run-all.sh 07 24            # 只跑指定编号
./run-all.sh -Clean           # 清理 build/

pwsh ./build.ps1              # PowerShell 等价入口
pwsh ./build.ps1 -Example 21
pwsh ./build.ps1 -Verbose
```

## 1.6 三个必须先建立的心智模型

1. **`=` 不是赋值，是合一。** `X = f(Y)` 是在断言「X 和 f(Y) 是同一个东西」，顺手把 Y 也
   绑上。`X == Y` 才是「现在是否已经相同」，永不绑定。这一对天天用错（04/05 章）。
2. **`is` 才算术。** `X = 1 + 2` 得到的是**项** `1+2`，不是 3；`X is 1 + 2` 才是 3。
   同理 `1+1 =:= 2` 为真而 `1+1 == 2` 为假（07 章）。
3. **回溯是自动的，剪枝要手动。** 程序慢十倍、给出多余解、或者在图上无限递归，根因几乎
   都在「选择点没剪干净」或「子句顺序不对」。`!`、`->`、`\+`、`once/1` 是用来管这件事的
   四把刀，各有各的语义陷阱（10 章）。

## 1.7 本教程地图

| 章 | 主题 | 章 | 主题 |
|---|---|---|---|
| [02](02-hello.md) | 第一个程序 | [14](14-io.md) | 输入输出 |
| [03](03-facts-rules.md) | 事实、规则与查询 | [15](15-text.md) | 文本处理 |
| [04](04-terms.md) | 项：原子/数字/变量/复合项 | [16](16-operators.md) | 运算符 |
| [05](05-unification.md) | 合一与同一性 | [17](17-database.md) | 动态数据库 |
| [06](06-backtracking.md) | 回溯与搜索树 | [18](18-dcg.md) | 定子句文法（DCG） |
| [07](07-arithmetic.md) | 算术与比较 | [19](19-parser.md) | 写一个解析器 |
| [08](08-lists.md) | 列表 | [20](20-exceptions.md) | 异常处理 |
| [09](09-recursion.md) | 递归、累加器与尾调用 | [21](21-constraints.md) | 约束求解 CLP(FD) |
| [10](10-cut.md) | 剪枝与否定 | [22](22-modules.md) | 模块与工程组织 |
| [11](11-higher-order.md) | 高阶谓词与元调用 | [23](23-testing.md) | 测试 |
| [12](12-metaprogramming.md) | 元编程 | [24](24-capstone.md) | 综合项目：解释器 |
| [13](13-all-solutions.md) | 解集收集 | | |

示例目录与章号一一对应：

```text
prolog/
  docs/          24 章正文（01 全景 → 24 收官项目）
  examples/      NN_topic/NN_topic.pl（02–24 共 23 个可运行示例）
  run-all.sh     三通道验证入口（bash）
  build.ps1      三通道验证入口（pwsh，判定与 run-all.sh 一致）
  CHEATSheet.md  语法速查 + 坑位总索引
```

部分章另有 `observe_*.pl`：这类文件专门用来**观察引擎差异**（原生模块、`library(clpfd)`
对比内建 FD），只要求「跑到底」，不参与逐字节比对。文件名后缀 `_swi` / `_gnu` 表示
只在某个引擎上跑。

## 1.8 怎么读

**先读正文 → 立刻 `cd examples/NN_topic && ../../run-all.sh NN` 跑一遍 → 改两行再跑。**

- **第一次接触逻辑编程**：02 → 03 → 05 → 06，到这里你会对「合一 + 回溯」有体感。
- **已经会别的语言**：直接看 04（项）和 07（算术），这两章是思维转换的关键。
- **想快速用起来**：08（列表）、10（剪枝）、13（收集解）覆盖日常八成写法。
- **做解析**：18–19 两章，从 DCG 识别器做到完整计算器。
- **做规则/推理系统**：17（动态库）+ 12（元编程）。
- **写可移植代码**：21、22、23 与每章末尾的坑位清单，外加 `CHEATSheet.md`。

---

下一章：[02 · 第一个程序](02-hello.md)
