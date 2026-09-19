# Coq 编程指南

一本从零到能用的 Coq 教程，25 章。每一章的代码都对应 `examples/` 下一个可以直接用 `coqc` 编译验证的 `.v` 文件——在这本教程里，**所有代码段都经过编译器实际检验**，包括那些「故意写错」的段落（它们用 `Fail` 包裹，编译器会确认它们确实如预期地失败）。

## Coq 是什么

Coq 是一个**证明助手**（proof assistant）：你用它定义数学对象、编写程序、陈述定理，然后**和它一起**把证明构造出来。它最与众不同的地方在于：证明不是写在纸上等人审阅，而是作为一个「项」交给 Coq 的内核做类型检查——**内核说这个证明合法，它就真的合法**，没有「看起来对」「应该没错」的余地。

这件事的价值已经被反复验证：经过 Coq 证明的 C 编译器 CompCert、四色定理的完整证明、有限单群分类中 255 页的 Feit–Thompson 定理证明，都是人类手工永远无法以这种置信度完成的工程。反过来说，写这些证明又确实是在「编程」——证明脚本就是程序，有变量、有分支、有复用、有调试。

所以这本教程叫「编程指南」而不叫「定理证明指南」：Coq 的日常使用 80% 是普通函数式编程（定义类型、写递归函数、组织模块），只有 20% 是证明——但那 20% 会反过来要求你把前 80% 写得**结构清晰**，因为归纳证明只对「按结构递归」的函数友好。学 Coq 会让你成为一名更好的函数式程序员。

三个先入为主的澄清，帮你在第一章就摆正期待：

1. **Coq 不是自动定理证明器**。它不会替你想证明思路，它只负责**检查**你给出的每一步。策略（tactic）能自动化的部分有限——就像编译器不会替你设计算法一样。
2. **Coq 的运行模型不适合写「带副作用的程序」**。没有 print、没有 mutable 全局变量、没有网络。数据与计算是纯粹的；要落地成真实程序，用 Extraction 抽取成 OCaml/Haskell 再运行（第 24 章会实践）。
3. **Coq 在 2024 年更名为 Rocq**。8.20 是最后一批以 "Coq" 命名的版本（本教程实测基于 8.20.1），之后是 Rocq 9.0+。搜资料时两个名字都要认得；Rocq 9 里标准库的名字也从 `Coq.*` 改成了 `Stdlib.*`，本教程的 `From Coq Require Import ...` 在 8.20 下实测有效。

## 目录

- [第 1 章 认识 Coq](#第-1-章-认识-coq)
- [第 2 章 工具链与运行方式](#第-2-章-工具链与运行方式)
- [第 3 章 第一个证明](#第-3-章-第一个证明)
- [第 4 章 类型系统](#第-4-章-类型系统)
- [第 5 章 表达式与运算符](#第-5-章-表达式与运算符)
- [第 6 章 元组与记录](#第-6-章-元组与记录)
- [第 7 章 模式匹配](#第-7-章-模式匹配)
- [第 8 章 列表](#第-8-章-列表)
- [第 9 章 归纳类型：自定义数据](#第-9-章-归纳类型自定义数据)
- [第 10 章 递归函数：Fixpoint 与终止性](#第-10-章-递归函数fixpoint-与终止性)
- [第 11 章 证明状态与 tactic 机理](#第-11-章-证明状态与-tactic-机理)
- [第 12 章 归纳证明](#第-12-章-归纳证明)
- [第 13 章 重写、化简与分情况讨论](#第-13-章-重写化简与分情况讨论)
- [第 14 章 命题逻辑](#第-14-章-命题逻辑)
- [第 15 章 谓词逻辑与 reflect](#第-15-章-谓词逻辑与-reflect)
- [第 16 章 高阶函数及其证明](#第-16-章-高阶函数及其证明)
- [第 17 章 Option：安全建模](#第-17-章-option安全建模)
- [第 18 章 策略武器库与模块](#第-18-章-策略武器库与模块)
- [第 19 章 表达式求值器：AST 入门](#第-19-章-表达式求值器ast-入门)
- [第 20 章 列表定律证明实战](#第-20-章-列表定律证明实战)
- [第 21 章 插入排序与正确性证明](#第-21-章-插入排序与正确性证明)
- [第 22 章 数值专题：nat、N 与 Z](#第-22-章-数值专题natn-与-z)
- [第 23 章 测试与断言风格](#第-23-章-测试与断言风格)
- [第 24 章 综合实战：表达式解释器与优化器](#第-24-章-综合实战表达式解释器与优化器)
- [第 25 章 坑清单与最佳实践](#第-25-章-坑清单与最佳实践)

对应示例在 `examples/` 目录下，文件名前缀为两位编号。运行方式（在 `coq/` 目录下）：

```powershell
.\build.ps1 -All                 # 编译全部示例
.\build.ps1 -File 03_first_proof.v   # 编译单个示例
.\build.ps1 -Clean               # 清理 build 目录
```

---

## 第 1 章 认识 Coq

### 1.1 证明助手是什么：一台「检查证明的机器」

先做一个思想实验。你在 C 语言里写了一个排序函数，怎么确认它是对的？跑一百万个随机测试？测试只能证明「没有找到反例」，不能证明「不存在反例」。数学上的办法是给出一个证明——但纸上的证明依赖**人**来审查，而人会累、会疏漏、会看走眼。

证明助手把「审查」这一环交给机器。在 Coq 里：

- 你**定义**数学对象和程序（本章就会看到：自然数、加法、列表都是「定义」出来的，不是内建的）；
- 你**陈述**想证明的命题（比如「对任意自然数 n，n + 0 = n」）；
- 你用一种叫**策略**（tactic）的命令语言，一步步把证明构造出来；
- Coq 的**内核**——一个刻意做得极小、因此可以被独立审计的程序——检查你构造的每一步是否逻辑上无懈可击。检查通过，定理封存；任何一步不成立，当场拒绝。

这个「极小内核检查一切」的设计哲学叫 de Bruijn 判据。它的含义很实际：你在构造证明时用的辅助工具（策略、自动化）**允许有 bug**——哪怕策略给你生成了错误的中间步骤，内核也会拒绝，你最多浪费时间，不会「证明」出假定理。这与「编译器有 bug 但 CPU 只认机器码」的分层信任是同构的。

一句话总结：**普通编程是「说服编译器你的程序类型正确」，Coq 编程是「说服内核你的命题逻辑成立」**。前者检查的是形状，后者检查的是实质。

### 1.2 Curry–Howard 对应：命题即类型，证明即程序

Coq 一切魔力的地基是一个漂亮的观察：**逻辑与类型是同一件事**。这就是 Curry–Howard 对应，理解它只需要下面这张表：

| 逻辑世界 | 类型世界 |
|---|---|
| 命题 P | 类型 P |
| P 成立（有证明） | 类型 P 有居民（能造出一个值） |
| 蕴含 P → Q | 函数类型 P -> Q |
| 「P 蕴含 Q」的证明 | 一个把 P 的证明变换成 Q 的证明的**函数** |
| 合取 P ∧ Q | 对偶类型 P \* Q |
| 析取 P ∨ Q | 变体类型 P + Q |
| 真 ⊤ / 假 ⊥ | 单元类型 unit / 空类型 Empty_set |
| 全称量词 ∀x:A, P x | 依赖函数类型 forall x : A, P x |

拿本教程第一个真正的证明（第 3 章）做例子：

```coq
Example square_3 : square 3 = 9.
Proof. reflexivity. Qed.
```

`square 3 = 9` 这个等式本身是一个**类型**（类型为 `Prop`，即「命题」）；证明它，就是**造出一个该类型的值**。`reflexivity` 造出来的值叫 `eq_refl`——「自反性」的见证。用 `Print square_3.` 亲眼看看（实测输出）：

```text
square_3 = eq_refl : square 3 = 9
```

**证明真的是一个项**。它有类型（就是那个命题），有值（eq_refl），能被打印、被存储、被别的证明引用。所谓「证明助手」，就是帮你造这种特殊值的编程环境。

而「蕴含即函数」也不抽象：

```coq
Definition modus_ponens (P Q : Prop) (hpq : P -> Q) (hp : P) : Q :=
  hpq hp.
```

读一遍：`hpq` 是「P 蕴含 Q」的证明——按上表它就是一个 `P -> Q` 的函数；`hp` 是 P 的证明——一个 P 类型的值；那么 `hpq hp` 就把 P 的证明变换成了 Q 的证明。**逻辑推理就是函数应用**。这五行在 Coq 里完全合法（第 14 章会真正编译它）。

### 1.3 出身、战绩与改名风波

Coq 起源于 1984 年法国 INRIA 的一个项目，由 Gérard Huet 与 Thierry Coquand 主导（"Coq" 正是致敬 Coquand 与 Huet 的首字母），其理论内核是 Coquand–Huet 的构造演算（Calculus of Constructions），后来 Christine Paulin-Mohring 等人加入归纳类型，形成今天的 CIC（Calculus of Inductive Constructions）。它属于「依赖类型」家族——类型可以依赖值（`n = 0` 就是一个依赖着 `n` 的类型），这是它表达力的来源。

几件用它完成、常被引用的大事，帮你建立「能干什么」的直觉：

| 成果 | 年份 | 内容 |
|---|---|---|
| CompCert | ~2006 起 | 一个 C 编译器，其**编译过程本身**被证明语义保持——工业级验证编译器 |
| 四色定理 | 2005 | Gonthier 与 Werner 把 1976 年那个依赖计算机的证明完整形式化 |
| Feit–Thompson 定理 | 2012 | 255 页群论证明由 Gonthier 领衔团队形式化，约 4 万行 |
| Fiat Crypto | 2010s | 自动生成经过验证的椭圆曲线密码算法实现 |

2024 年，社区投票决定将项目更名为 **Rocq**。原因说来话短：原名在英语里有不雅的俚语含义，给学术推广添了不少尴尬。版本脉络是：**8.20.x 是最后一批叫 Coq 的版本，之后是 Rocq 9.0**。对初学者的影响有两个：

1. 搜索资料时，"Coq" 与 "Rocq" 指同一个东西，新旧教程混着看即可；
2. 标准库的命名空间从 `Coq.*` 改成了 `Stdlib.*`——本教程基于 8.20.1，写法是 `From Coq Require Import List.`；在 Rocq 9 上要么换成 `From Stdlib Require ...`，要么开启兼容开关。

### 1.4 Coq 能做什么、不擅长什么

**适合**：

- 写「必须对」的代码：编译器优化 pass、密码学算法、并发协议、航天控制逻辑——凡是 bug 代价高昂的地方；
- 形式化数学：把定义、定理、证明全部写下来，消灭「留作练习」和「易证」；
- 学习并彻底吃透离散数学、逻辑、数据结构——Coq 不会让你「似懂非懂地通过」；
- 做依赖类型、类型论方向的科研。

**不擅长**（诚实清单）：

- 快速出活的原型脚本：没有随手 print 调试、没有丰富的包生态；
- 字符串/文本处理：能做但笨重（第 24 章会体会到）；
- 浮点密集型计算：默认数系是为证明设计的；
- 「自动证明」：自动化程度有限，证明思路始终是你的活。

一个常见的学习路线对照：先学 Coq 再学别的函数式语言会很顺（Haskell/OCaml 都是它的「降级简化版」）；反过来，有一点 Haskell/OCaml 底子再学 Coq，入门会快很多。零函数式基础也完全可以从本教程开始——前 10 章就是一本函数式编程入门。

### 1.5 与 Lean 4 / Agda / Isabelle 的对比

证明助手里最常被一起提到的四个：

| | Coq/Rocq | Lean 4 | Agda | Isabelle/HOL |
|---|---|---|---|---|
| 理论基础 | CIC，依赖类型 | 依赖类型 + 经典数学库 | MLTT，依赖类型 | HOL（高阶逻辑，非依赖） |
| 证明风格 | tactic 为主 | tactic + 项混合 | 交互式项构造为主 | tactic + 强自动化 |
| 标准数学库 | 中等 | mathlib 极大且活跃 | 中等 | AFP 庞大 |
| 代码抽取 | OCaml/Haskell/Scheme | 无官方（C 生成实验性） | 有 | 可生成代码 |
| 生态气质 | 老牌、计算机科学向 | 新锐、数学向、社区增长最快 | 学院派 | 德系、自动化强 |
| 代表应用 | CompCert、四色定理 | Fermat 大定理形式化（进行中） | 类型论科研 | seL4 微内核验证 |

选 Coq 的理由：教学资源最系统（Software Foundations 是全领域最好的入门材料之一，本教程多处借鉴其编排）、计算机科学方向的积累最深、工具链成熟稳定。选别的理由：追求数学前沿去 Lean，追求极致自动化去 Isabelle。它们之间的核心技能——「把性质说清楚，把证明按结构做出来」——完全互通。

### 1.6 怎么读这本教程

- **动手至上**。每章先把 `examples/` 里对应文件跑一遍，再回头读讲解。Coq 的「证明状态」是动态的，纸上读战术如隔靴搔痒。
- 前 10 章可以当函数式编程书读，证明内容很少；第 11 章开始证明成为主角。
- 每章末尾的**坑位清单**都是实测（在 8.20.1 上真实翻车过才写进去），值得在做题/写代码前扫一眼。
- 卡住时回到第 2 章的「向 Coq 提问」四件套（`Print` / `About` / `Locate` / `Search`）——Coq 的答案永远比搜索引擎准。
- 本教程刻意**不引入任何外部库**（不用 stdpp、不用 MathComp），一切用标准库最朴素的部分，让你清楚每个定义的来龙去脉。

### 1.7 示例 01：Check / Compute / 证明

对应示例：`examples/01_intro.v`。它演示与 Coq 对话的三种基本句子：

```coq
Check 0.                    (* 0 : nat —— 问类型 *)
Compute (6 * 7).            (* = 42 : nat —— 求值 *)

Example plus_2_2 : 2 + 2 = 4.
Proof. reflexivity. Qed.    (* 断言 + 证明 *)
```

编译它：

```powershell
.\build.ps1 -File 01_intro.v
```

输出里值得注意的三个细节（实测）：

1. `Check (S (S (S O))).` 打印的是 `3 : nat`——你手写的「后继链」会被数字记号自动美化显示；
2. `Compute` 的结果带有类型标注（`= 42 : nat`），提醒你 Coq 里**值与类型永远成对出现**；
3. `Check (fun A (a : A) => a).` 打印 `forall A : Type, A -> A`——一个匿名函数就有多态类型，这是后面所有「多态」内容的种子。

### 1.8 小结

- 证明助手 = 定义 + 陈述 + 构造证明 + 内核检查；信任基础是极小的内核；
- Curry–Howard：命题=类型、证明=程序（值）、蕴含=函数、量词=依赖类型；
- Coq 1984 年生于 INRIA，2024 年更名 Rocq；8.20 是最后的 Coq 命名版本；
- 它不自动找证明、不适合带副作用的脚本编程；
- 学习心法：动手、按结构思考、向 Coq 本人提问。

---

## 第 2 章 工具链与运行方式

对应示例：`examples/02_toolchain.v`

### 2.1 安装与验证

本教程的实测环境：

- Windows 11，Coq 8.20.1（scoop 安装，位于 `G:\scoop\apps\coq\current`）
- 这套安装自带 `coqc`（批处理编译器）、`coqtop`（交互式顶层）、`coqide`（图形界面）、`coqchk`（独立检查器）等工具

获取 Coq 的几条路：

| 方式 | 说明 |
|---|---|
| 官方安装器 / zip | 从 rocq-prover.org 或 GitHub Releases 下载，含 CoqIDE |
| Windows 下 scoop | `scoop install coq`，本教程环境即此 |
| opam（跨平台） | `opam install coq.8.20.1`，版本管理最灵活 |
| WSL / Linux 包管理器 | apt/dnf 版本可能偏旧，注意核对 |

验证安装：

```powershell
G:\scoop\apps\coq\current\bin\coqc.exe --version
(* The Coq Proof Assistant, version 8.20.1
   compiled with OCaml 4.14.2 *)
```

### 2.2 coqtop：交互式问答

证明的构造是交互式的，所以 Coq 的「主战场」是顶层解释器。启动：

```powershell
G:\scoop\apps\coq\current\bin\coqtop.exe
```

```text
Welcome to Coq 8.20.1
Coq <
```

三条使用纪律：

1. **每个句子以句点 `.` 结尾**。没有句点，Coq 就一直等你把话说完——新手最常以为「卡死了」，其实只是在等句号；
2. 提示符 `Coq <` 表示当前**没有**打开的证明；一旦你开始一个 `Theorem`，提示符变成待证明状态，用 `Show.` 随时重看当前目标；
3. `Quit.` 退出（或 Ctrl-D）。

一段典型会话（可直接照抄体验）：

```text
Coq < Check (fun n => n + 1).
fun n : nat => n + 1
     : nat -> nat

Coq < Compute (2 + 2).
     = 4
     : nat

Coq < Example e : 2 + 2 = 4.

Coq < Proof. reflexivity. Qed.

Coq < Quit.
```

在证明中途，`Show.` 显示当前目标；`Abort.` 放弃当前证明；`Restart.` 从头再来。这些是交互调试的四件常备工具。

### 2.3 coqc：批处理编译

`coqc file.v` 把整个文件一口气编译检查，产出 `file.vo`（编译产物，供其他文件 `Require` 引用）：

```powershell
G:\scoop\apps\coq\current\bin\coqc.exe examples\02_toolchain.v
```

本仓库的 `build.ps1` 做了三件贴心事：把 `examples/*.v` 复制到 `build/examples/` 并加 `ex_` 前缀（**源码目录永远干净**，`.vo` 等产物不会污染 git）、逐个调用 `coqc -q`、任何失败立刻中断报错。日常用它：

```powershell
.\build.ps1 -All                    # 全部示例
.\build.ps1 -File 02_toolchain.v    # 单个
.\build.ps1 -Clean                  # 清理产物
```

`-q` 表示跳过用户 rcfile（保证本教程结果可复现）。

一个重要的实测差异：**`Fail` 命令的提示语只在交互模式显示**。`Fail` 用来断言「接下来的命令应当失败」——coqtop 里它会友好地打出失败原因；coqc 批处理下静默通过。所以本教程示例里用 `Fail` 演示的错误信息，请到 coqtop 里复现着看。

### 2.4 CoqIDE 与 VS Code（VSCoq）

交互式写证明，纯命令行的体验是裸奔。两个图形选项：

- **CoqIDE**：安装包自带（`coqide.exe`），零配置开箱即用。快捷键 F10（下一句）/ F11（回退）逐步执行证明，右侧面板实时显示证明状态——**强烈建议初学者前几章用它**，「目标如何随策略变化」必须亲眼看过才能内化；
- **VS Code + VSCoq 扩展**：现代编辑体验，同样的逐步求值能力。已在用 VS Code 的读者选这条。

它们与 coqtop 本质相同：把句子一句句喂给 Coq 内核，把证明状态画给你看。工具随喜好，内核只有一个。

### 2.5 学会向 Coq 提问：Print / About / Locate / Search

Coq 最被低估的能力：**它比文档更懂自己**。四个问询命令是贯穿全书的主角，示例 `02_toolchain.v` 逐一演示了它们（编译该文件，输出就是下面的内容）。

**`Print`——「这个东西是怎么定义的？」**

```coq
Print nat.
```

```text
Inductive nat : Set :=  O : nat | S : nat -> nat.
```

一句话看清 nat 的真身：一个只有两个构造子的归纳类型。再比如 `Print Nat.add.` 会显示加法是一个在第一个参数上递归的 `fix`——「加法是递归定义出来的」这件事，Print 直接展示给你。

**`About`——「这个符号的档案是什么？」**

```coq
About eq.
```

```text
eq : forall {A : Type}, A -> A -> Prop
```

类型、隐式参数、所在模块，一次看全。任何「这个函数到底吃什么参数」的疑问都先问 About。

**`Locate`——「这个记号绑定到哪里？」**

```coq
Locate "+".
```

```text
Notation "{ A } + { B }" := (sumbool A B) : type_scope
Notation "A + { B }" := (sumor A B) : type_scope
Notation "x + y" := (Nat.add x y) : nat_scope
Notation "x + y" := (sum x y) : type_scope
```

同一个 `+`，在不同**作用域**（scope）里是不同的东西：nat 里是加法，类型层面是和类型。这解释了 Coq 里大量「符号重载」现象——记号按作用域解释，规则清晰但需要你有这个意识。

**`Search`——「库里有没有长得像这样的定理？」**

```coq
Search (_ + 0).
```

```text
plus_n_O: forall n : nat, n = n + 0
```

按**形状**搜索全部已知定理——下划线是通配符。写证明卡住时，先描述一下「我想要的结论长什么样」，让 Search 找。配合关键字过滤（`Search (_ <= _) "le_n_S".`）更好用。

这四个命令的意义再强调一次：**Coq 是一个可查询的形式系统，而不是一个黑盒**。养成「先问再搜」的习惯，是脱离初学者的分水岭。

### 2.6 .v 文件的组织习惯

本教程示例统一遵循的模板：

```coq
(* 标题注释：本章主题、要点 *)

From Coq Require Import Arith.   (* 需要的库，统一从 Coq 命名空间引入 *)

Module Ex02Toolchain.            (* 整章包进一个 Module，
                                    避免与其他章节重名冲突 *)

(* ... 正文 ... *)

End Ex02Toolchain.
```

几个要点：

- `From Coq Require Import X.` 的意思是「从 Coq 这个命名空间（8.20 的标准库）加载模块 X 并 `Import` 其内容」。`Require` 加载，`Import` 打开其中的名字与记号——两步是独立的，`From` 用来消除歧义；
- 注释是 `(* ... *)`，可嵌套——这一点与 C 系语言不同，`(* a (* b *) c *)` 完全合法；
- 本教程实测：**UTF-8（无 BOM）的中文注释可直接通过 coqc**，因此示例注释全用中文；
- `Module ... End` 是命名空间：第 18 章会展开讲模块系统（含签名与封装）。

### 2.7 本章坑位清单（实测）

1. **忘写句点 `.`**：coqtop 一动不动地「等你把话说完」，看起来像卡死；
2. **`Fail` 的提示语在 coqc 下不打印**：想看失败原因去 coqtop；
3. **`8 / 2` 直接报错 `Unknown interpretation for notation "_ / _"`**：nat 的 `/` 记号不在默认作用域里，必须先 `From Coq Require Import Arith`（或写全 `Nat.div 8 2`）。乘加 `* +` 是默认有的，除法模运算不是——为什么？因为 `+` `*` 由 `Init` 阶段加载，而 `/` `mod` 的记号绑定在 Arith 库里。同一家族的还有 `=?` `<=?` `<?` `^`（也要 Arith）和 `&&` `||`（要 `Open Scope bool_scope`）——初学者第一周必踩；
4. **在证明中途退出**：忘记 `Qed.`/`Abort.` 就开始下一个定义，报错位置莫名其妙——先 `Show.` 确认自己是不是还在证明模式里；
5. **Rocq 9 与 8.20 的库路径不同**：`From Coq Require ...` vs `From Stdlib Require ...`，抄新资料时注意版本。

---

## 第 3 章 第一个证明

对应示例：`examples/03_first_proof.v`

### 3.1 三种句子：命令、策略与项

打开一个 `.v` 文件，你会看到三种成分。分清它们，Coq 的报错才有读法：

| 成分 | 例子 | 什么时候起作用 |
|---|---|---|
| **vernacular（命令）** | `Definition` `Example` `Print` `Check` `Require` `Qed` | 管理环境：声明、查询、加载 |
| **tactic（策略）** | `reflexivity` `intros` `simpl` `rewrite` `destruct` | 只在证明模式里，改造证明状态 |
| **term（项）** | `3` `S O` `fun n => n` `Nat.add 2 3` | 数据与证明的本体，类型检查的对象 |

一个文件就是一串命令；命令里嵌着项；`Proof.` 到 `Qed.` 之间是策略的地盘。第 11 章会精确解释策略如何工作，本章只需要「证明 = 用策略造项」这个直觉。

### 3.2 Definition：定义一个可计算对象

```coq
Definition square (n : nat) : nat := n * n.
```

读法：`Definition 名字 (参数 : 类型) : 返回类型 := 体.`。它是纯函数式的「let」——给 `fun n => n * n` 这个项起了个名字。三件套问询都能作用于它（实测输出）：

```coq
Check (square 3).   (* square 3 : nat *)
Compute (square 3). (* = 9 : nat *)
Print square.       (* square = fun n : nat => n * n
                        : nat -> nat *)
```

注意 `Print` 显示的是「编译器眼中的定义」——参数、类型、函数体，原样展开。定义没有魔法，`square 3` 就是 `3 * 3`，`Compute` 老老实实把它算出来。

### 3.3 Example / Proof / reflexivity / Qed 逐行解剖

现在进入正题。四行一个完整的证明：

```coq
Example square_3 : square 3 = 9.
Proof. reflexivity. Qed.
```

逐行拆解：

**第一行 `Example square_3 : square 3 = 9.`**
声明一个对象 `square_3`，其类型是命题 `square 3 = 9`。此刻它还没有「值」（证明）——就像你宣布「我要定义一个返回 bool 的函数」但还没写函数体。屏幕上（交互模式下）出现的证明状态是：

```text
1 subgoal

  ============================
  square 3 = 9
```

横线下面是**目标**（goal）：需要构造出 `square 3 = 9` 这个类型的一个居民。

**第二行 `Proof.`**
正式进入证明模式。它本身不做事，是个仪式性开关（默认开启，写出来是为了可读性）。

**第三行 `reflexivity.`**
策略登场。它检查：等式两边能否**化简到同一个值**？`square 3` 化简得 `9`，右边本来就是 `9`——两边相同，于是它构造出证明项 `eq_refl`（「自反性」的见证：`x = x` 型等式的通用证明）。目标消失，证明状态归零。

**第四行 `Qed.`**
封印。把从 `Proof.` 以来的策略脚本编译成一个证明项，交**内核**重新独立做一次类型检查（策略层即使有 bug 也骗不过这一步），通过后把 `square_3 : square 3 = 9` 存入环境。从此 `square_3` 是一个可引用的定理。

这套「陈述 → 开目标 → 打策略 → 封印」的节奏贯穿全书。初学时把四行**分开写、逐行执行**（CoqIDE 里按 F10），亲眼看目标怎么出现、怎么消失——这是建立证明直觉最快的方式。

### 3.4 证明是一个项：Print 它

Curry–Howard 不是口号，可以验证：

```coq
Print square_3.
```

```text
square_3 = eq_refl : square 3 = 9
```

`square_3` 的「值」是 `eq_refl`——一个由 `=` 类型的唯一构造子构成的项。就像 `list` 的值由 `nil`/`cons` 构成，**等式的值由 `eq_refl` 构成**。以后学到 `rewrite` 会看到：使用定理就是把它的证明项当作数据去变换。

### 3.5 失败长什么样：Fail 与 Abort

证明失败是日常。把断言写错：

```coq
Example broken : 2 + 2 = 5.
Proof.
  Fail reflexivity.
  (* The command has indeed failed with message:
     Unable to unify "5" with "4". *)
Abort.
```

两个新命令：

- **`Fail`**：断言「下一个命令应当失败」。失败了，`Fail` 成功；没失败，`Fail` 反而报错 `The command has not failed!`。它是**把错误变成可编译文档**的机制——本教程大量用它把坑写进示例。注意（实测）：失败提示语只在 coqtop / CoqIDE 里显示，coqc 批处理下静默；
- **`Abort.`**：放弃当前证明，环境回到陈述之前。证明做不下去时用它脱身，别把烂尾的 `Theorem` 留在文件里。

类型错误同样可以被 `Fail` 预言（示例 03 里就有）：

```coq
Fail Check (0 : bool).
(* The term "0" has type "nat" while it is expected to have
   type "bool". *)
```

Coq 的报错信息值得逐字读：**谁**（the term "0"）、**是什么**（has type "nat"）、**哪里不匹配**（expected "bool"）。它几乎总在说真话——第 25 章的坑清单里，一半条目的排查方法就是「把错误信息完整读完」。

### 3.6 Theorem 家族与命名习惯

以下关键字**语法地位完全相同**，都是「声明一个命题类型的对象」：

| 关键字 | 语义习惯 |
|---|---|
| `Theorem` | 比较重要的结果 |
| `Lemma` | 服务于主定理的中间结果 |
| `Corollary` | 由主定理直接派生 |
| `Proposition` | 中等重要性的陈述 |
| `Fact` / `Remark` | 顺手记下的小结论 |
| `Example` | 通常是算一算就能验证的具体断言 |

新手纠结「该用哪个」纯属浪费感情——随便挑，团队一致即可。本教程的习惯：具体计算断言用 `Example`，一般性结论用 `Theorem`。

### 3.7 Admitted：技术债开关

有一个危险的逃生门必须现在讲清楚：

```coq
Theorem i_promise : forall n : nat, n + 0 = n.
Proof. Admitted.   (* 假装证完了！ *)
```

`Admitted.` 把定理**作为公理**收下——之后所有依赖它的证明都建立在空中楼阁上。它是开发过程中「先跳过这段，后面再补」的合法手段，但**任何提交/发布的代码里都不该有它**。检查工具（第 23 章）：`Print Assumptions 定理名.` 会列出该定理依赖的全部公理——输出 `Closed under the global context` 才是干净证明。

### 3.8 本章坑位清单（实测）

1. **句子忘句点 / 多句点**：`Proof. reflexivity. Qed.` 一行三句，句点属于「句子」不属于「行」；
2. **`Fail` 在 coqc 下不打印失败原因**（见 3.5）；
3. **`Qed` 时才发现没证完**：还剩目标就 `Qed.`，报错 `Attempt to save an incomplete proof`——错误行号在 `Qed` 处，但真正的问题在前面；养成 `Show.` 的习惯；
4. **陈述里函数名拼错**：`square3` vs `square_3`，报的是 `The reference square3 was not found`，查拼写；
5. **`Admitted` 留进正式代码**：`Print Assumptions` 一查便知，CI 里应当禁；
6. **想当然写 `8 / 2`**：不加 `Require Import Arith` 就是记号未定义错误（第 2 章坑 3，本章示例文件头也注明了）。

---

## 第 4 章 类型系统

对应示例：`examples/04_types.v`

### 4.1 nat 的真身：一条 S 链

Coq 里没有内建的「机器整数」。自然数是**定义出来的**：

```coq
Print nat.
```

```text
Inductive nat : Set :=  O : nat | S : nat -> nat.
```

翻译成人话：`nat` 类型有两个构造子（constructor）——

- `O : nat`——零；
- `S : nat -> nat`——后继（successor），「加一」。

于是每个自然数都是一条链：`1 = S O`，`2 = S (S O)`，`3 = S (S (S O))`……运行 `Compute (S (S (S O))).` 得 `= 3 : nat`——打印时 Coq 自动把链折叠成数字给你看（实测）。

这个设计初看低效（确实低效，第 22 章解决），换来两样无价的东西：

1. **归纳原理**：「对 O 成立、对 S k 也成立（假设对 k 成立），则对所有自然数成立」——第 12 章的归纳证明直接建立在 nat 的形状上；
2. **类型上无溢出**：数要多大有多大，`Check (2 ^ 100).` 合法（`^` 记号需 `Arith`，实测）。

但马上泼一盆冷水（实测坑）：**「类型装得下」不等于「算得动」**。一元表示下 `Compute (Nat.pow 2 100).` 会直接**内存耗尽**——2¹⁰⁰ 约需 10³⁰ 个 `S` 构造子，宇宙里的原子都不够存。「无溢出」是逻辑层面的性质；工程层面的大数计算请用二进制的 `N`/`Z`（第 22 章）。

把类型理解为「值的集合 + 形状规则」，nat 是最好的第一课：集合是所有 S 链，形状规则是「只能是 O 或 S 套另一个 nat」。

### 4.2 常用内置类型速览

| 类型 | 构造子 | 例子 |
|---|---|---|
| `nat` | `O`、`S` | `0`、`3`、`S (S O)` |
| `bool` | `true`、`false` | `negb true` |
| `list A` | `nil`（`[]`）、`cons`（`::`） | `[1; 2; 3]` |
| `option A` | `None`、`Some` | `Some 5` |
| `A * B` | 唯一的二元组构造子 | `(3, true)` |
| `sum A B`（`A + B`） | `inl`、`inr` | `inl 3` |
| `unit` | `tt` | `tt` |
| `Empty_set` | 无 | 不存在值 |

三个观察：

- **`A * B` 与 `A + B` 的记号容易和乘法加法搞混**——它们在 `type_scope` 作用域里是「积类型/和类型」（对偶与变体），在 `nat_scope` 里才是算术。`Locate "*"` 可以看到全部绑定（实测时你会发现 `*` 的解释比 `+` 还多）；
- **`list`/`option` 都是「参数化类型」**：装什么类型的东西由 `A` 决定，这叫多态（4.5 节）；
- **`Empty_set` 没有构造子**——造不出任何值。按 Curry–Howard，它对应「假命题」：`Empty_set -> A` 类型的函数能从「假」推出任何东西（第 14 章用它定义否定）。

### 4.3 万物皆有类型，类型也有类型

Coq 是「三层都有一致结构」的系统：值有类型，类型也有类型（称为 **sort**），sort 之上还有层级：

```coq
Check 3.       (* 3 : nat *)
Check nat.     (* nat : Set *)
Check bool.    (* bool : Set *)
Check Set.     (* Set : Type *)
Check Type.    (* Type : Type —— 打印时隐藏层级编号 *)
```

三个 sort 的分工，初学阶段记这个版本就够：

| Sort | 住着谁 | 例子 |
|---|---|---|
| `Set` | 数据类型 | `nat`、`bool`、`list nat` |
| `Prop` | 命题 | `3 = 3`、`forall n, n + 0 = n` |
| `Type` | 上面两者共同的「父类」 | `Set : Type`、`Prop : Type`，以及 `list` 这样的类型构造子 |

日常说「类型」时通常指 `Set`/`Type` 层的居民；说「命题」指 `Prop` 层的居民。**Prop 里的东西不可计算**——`3 = 3` 不能 `Compute`，它只能被证明或证伪；这与接下来这条对照着记。

### 4.4 Prop 与 bool 的第一次照面

新手最困惑的一对：`3 = 3`（Prop）与 `Nat.eqb 3 3`（bool）有什么区别？

```coq
Check (3 = 3).       (* 3 = 3 : Prop *)
Check (Nat.eqb 3 3). (* Nat.eqb 3 3 : bool *)
Compute (Nat.eqb 3 3).  (* = true : bool *)
Compute (3 = 3).        (* = 3 = 3 : Prop —— 不报错！见下 *)
```

- **bool 是数据**：`true`/`false` 两个值，程序可以对它 match、if、计算——**运行时**用来做分支；
- **Prop 是命题**：`3 = 3` 是一个断言，回答它要靠**构造证明**，而不是「算」。

有个容易想当然的地方（实测）：`Compute (3 = 3).` 并不报错——它打印 `= 3 = 3 : Prop`。Compute 只是把命题这个项**规范化后原样还给你**，它不回答「成立与否」；`3 = 3` 也不是 `true`。命题的真假是证明的事，求值帮不上忙。

「都是相等性，为什么要两套？」——因为它们回答不同的问题：`Nat.eqb 3 3` 问「程序算出来是不是 true」（可计算但只对具体值有意义）；`3 = 3` 及其推广 `forall n, n + 0 = n` 表达数学断言（覆盖无穷多情况，无法靠计算穷尽）。两座桥（`Nat.eqb_eq`：bool 等于 true 当且仅当命题成立）在第 15 章的 reflect 主题下正式讲。

### 4.5 类型推断：标注可省则省

Coq 的类型推断能力与 OCaml 同源（都源自 Hindley–Milner 传统，Coq 加了依赖类型的扩展），绝大多数标注可以省：

```coq
Definition fortytwo := 42.
Check fortytwo.        (* fortytwo : nat —— 推断出来的 *)

Definition double (n : nat) : nat := 2 * n.
Definition double' n := 2 * n.
Check double'.         (* double' : nat -> nat —— 参数类型也能推 *)
```

但**省标注不等于不检查**：

```coq
Fail Check (double true).
(* The term "true" has type "bool" while it is expected
   to have type "nat". *)
```

什么时候该写标注？本教程的习惯：**公开定义写全**（`Definition f (n : nat) : nat := ...`）——类型即文档且防推断意外；**内部辅助小函数**可省。教学代码一律写全。

### 4.6 多态与隐式参数

「对任何类型 A 都成立」的函数，把 A 作为参数：

```coq
Definition id {A : Type} (a : A) : A := a.
```

花括号 `{A : Type}` 表示**隐式参数**：调用时不用写，由其他参数推断：

```coq
Check (id 10).       (* id 10 : nat —— A 被推断为 nat *)
Check (id true).     (* id true : bool —— A 被推断为 bool *)
Check (@id nat 10).  (* @id nat 10 : nat —— @ 关掉隐式，手动给全 *)
```

`@` 是个重要前缀：「接下来的参数全部显式给」。两个使用场景：

1. 想显式指定隐式参数（推断结果不合意时）；
2. 引用多态常量本身——`Check id.` 只会看到 `id : forall A : Type, A -> A`，而 `Check (@id nat).` 能谈到「nat 版本的 id」。

标准库的空表与拼表也这样用：

```coq
Check (@nil nat).        (* @nil nat : list nat —— 空表要说明装什么 *)
Check (cons true nil).   (* (true :: nil)%list : list bool *)
```

注意打印时 Coq 自动换用 `::` 记号显示。`list` 的 `A` 是隐式的，所以 `[1; 2]` 不需要写 `list nat [1; 2]`——糖衣之下，一切仍是显式的类型检查（第 8 章展开列表）。

### 4.7 构造子的纪律

每个构造子只接受**自己类型声明的参数**，一点不含糊：

```coq
Fail Check (S true).
(* The term "true" has type "bool" while it is expected
   to have type "nat". *)
```

`S` 只吃 nat。跨类型转换不存在「隐式提升」——整数转浮点、char 转 int 这类 C 的日常，在 Coq 里都必须显式发生。这在证明语境是刚需：**隐式转换是逻辑漏洞的温床**（`0.999... == 1` 型的意外），Coq 从类型层根除了它们。

### 4.8 本章坑位清单（实测）

1. **以为 `3` 是机器整数**：它是 `S (S (S O))`；性能敏感场景第 22 章换 `N`/`Z`；
2. **以为 `Compute (Nat.pow 2 100)` 只是慢**：实测直接 **内存耗尽**——一元表示撑不起大数，`Check` 装得下≠`Compute` 算得动；
3. **以为 `Compute (3 = 3)` 会报错**：实测打印 `= 3 = 3 : Prop`——求值只做规范化，不回答命题真假；
4. **隐式参数想显式给却忘了 `@`**：`Check (id nat 10).` 会把 nat 当成 A 的值——必须 `@id nat 10`（实测如期失败）；
5. **`A * B` / `A + B` 与算术混淆**：作用域决定含义，怀疑时 `Locate "+"`；
6. **以为类型标注是「建议」**：写错照样编译失败，标注参与检查，不是注释。

---

## 第 5 章 表达式与运算符

对应示例：`examples/05_expressions.v`

### 5.1 记号是语法糖：从 + 到 Nat.add

Coq 里几乎所有中缀运算符都是**记号**（notation）——漂亮的表面语法，底下是普通函数应用：

```coq
Locate "+".
(* Notation "x + y" := (Nat.add x y) : nat_scope  <-- 默认生效 *)
Compute (Nat.add 2 3).   (* = 5 : nat *)
Compute (2 + 3).         (* = 5 : nat —— 与上一行完全等价 *)
```

这不是知识炫技，而是**排错技能**：当 `+` 的行为诡异时（比如作用域不对），把它还原成 `Nat.add` 再看，问题立刻显形。记号按**作用域**解释，同一个符号在不同作用域是不同的函数——这是 Coq 与 C 系语言「运算符重载」的本质区别：绑定是**全局声明式**的，且随时可查（`Locate`）。

### 5.2 nat 算术全家福与两大坑

先给表（全部实测）：

| 运算 | 写法 | 例子与结果 |
|---|---|---|
| 加 | `x + y` | `2 + 3 = 5` |
| 减 | `x - y` | **`1 - 2 = 0`**（截断！） |
| 乘 | `x * y` | `6 * 7 = 42` |
| 除 | `x / y` | `7 / 2 = 3`；**`5 / 0 = 0`**；需 `Arith` |
| 模 | `x mod y` | `5 mod 2 = 1`；`0 mod 5 = 0`；需 `Arith` |
| 最大/最小 | `Nat.max` / `Nat.min` | `Nat.max 3 7 = 7` |
| 幂 | `Nat.pow` | `Nat.pow 2 10 = 1024` |

nat 是自然数——**没有负数**。于是两个从 C/Python 带来的直觉当场翻车：

**坑一：截断减法。**

```coq
Compute (1 - 2).   (* = 0 : nat —— 不是 -1！ *)
```

减到 0 就停。若你的算法依赖负中间结果（比如有向差值），要么换 `Z`（见 5.6），要么先 `Nat.max` 钳住方向。更要命的是证明：`n - n = 0` 对，但 `n - m + m = n` **不对**（m > n 时翻车），依赖算术直觉前先想想截断。

**坑二：除以 0 不崩溃，规定为 0。**

```coq
Compute (5 / 0).   (* = 0 : nat —— 不是异常，是定义 *)
```

`x / 0 = 0` 是标准库的规定。它保证了除法**全函数**（任何输入都有输出，证明好做），代价是「除零错误」在 Coq 里**静默**发生——把错误吞进值里。工程上警惕：从 C 移植的算法若隐含「除零必崩」的假设，在 Coq 里不会崩，只会悄悄算错。

还有一个语法层面的坑（实测）：`- 1` 这样的**一元负号在 nat 上不存在**——`Fail Check (- 1).` 如期失败（记号未绑定）。要负数，下一节的 Z 在等你。

### 5.3 比较：eqb / leb / ltb

nat 的比较函数返回 **bool**（可计算的数据）：

| 函数 | 记号 | 语义 |
|---|---|---|
| `Nat.eqb a b` | `a =? b` | 相等？ |
| `Nat.leb a b` | `a <=? b` | a ≤ b？ |
| `Nat.ltb a b` | `a <? b` | a < b？ |

```coq
From Coq Require Import Arith.   (* 三个记号都要它（实测） *)

Compute (Nat.eqb 3 3).   (* = true *)
Compute (Nat.leb 3 7).   (* = true *)
Compute (Nat.ltb 7 3).   (* = false *)
```

记号 `=?` `<=?` `<?` 的后缀 `?` 是精心设计：**提醒你返回的是 bool（可能为假的问题）而非 Prop（已被证明的断言）**。两套体系在 4.4 节见过面，第 15 章正式架桥。

用比较函数拼一个有意义的定义：

```coq
Definition abs_diff (a b : nat) : nat :=
  if Nat.leb a b then b - a else a - b.
```

这是典型的 Coq 小函数模式：**用 `leb` + `if` 做分支**。第 13 章会证明它的性质（比如 `abs_diff a b = abs_diff b a`），到时候你会体会到「函数按结构写，证明才好做」。

### 5.4 bool 运算

三个基础函数，名字直白：

```coq
Compute (andb true false).   (* = false —— 与，记号 && *)
Compute (orb true false).    (* = true  —— 或，记号 || *)
Compute (negb true).         (* = false —— 非 *)
```

与 C 不同的是：**没有隐式真值**——`if 1 then ...` 这种写法在多数语言里要么合法（C 的非零即真）要么报错（Java），在 Coq 里的真实行为出乎意料，是下一节的头号坑。

顺带一个实测坑：`&&` `||` 记号**默认不可用**（报 `Unknown interpretation for notation "_ && _"`）——它们绑定在 `bool_scope` 里，而这个作用域默认没开。要么 `Open Scope bool_scope.`，要么老老实实写 `andb`/`orb`（本教程示例用后者）。这和 `/` `mod` `=?` `^` 需要 `Arith` 是同一类问题：**记号是按作用域懒加载的，裸环境只有最基础的一套**。

### 5.5 if 的真身（本章大坑，实测）

教科书会告诉你「Coq 的 if 条件必须是 bool」。**实测不是**：

```coq
Compute (if 1 then 2 else 3).   (* = 3 : nat —— 编译通过！走了 else！ *)
Compute (if 0 then 2 else 3).   (* = 2 : nat —— 走了 then *)
```

`1` 是 nat，怎么就能 if 了？因为 **Coq 的 if 是两分支 match 的语法糖**：条件可以是**任何恰好有两个构造子的归纳类型**——第一个构造子走 then，第二个走 else。`nat` 恰好只有 `O` 和 `S` 两个构造子，于是 `if n` 就是 `match n with O => then分支 | S _ => else分支 end`：**0 当「假」、非零当「真」**——不小心复刻了 C 的语义！

bool 只是「两构造子俱乐部」里最常用的成员（`true` 第一个、`false` 第二个，所以行为「正常」）；另一个常客是 `sumbool`（`left`/`right`，第 14 章登场）。构造子数量不是两个就真的不行——`Z` 有三个：

```coq
Fail Compute (if 1%Z then 2 else 3).   (* 如期失败 *)
```

实用结论有三条：

1. **别写 `if n then ...`（条件是 nat）**——合法但可读性陷阱，明确用 `Nat.eqb n 0` 表达意图；
2. 看到别人代码里条件不是 bool 不要惊讶，先 `Print` 一下条件类型数数构造子；
3. 反过来，你自己定义的两构造子类型（第 9 章会定义一堆）天然支持 if——这是设计 API 的小甜头。

### 5.6 Z 速览：%Z 作用域

要负数、要机器风格的整数运算，用 `Z`（无界二进制有符号整数，第 22 章详解）：

```coq
From Coq Require Import ZArith.

Compute (2 - 5)%Z.     (* = -3 : Z *)
Compute (- 3)%Z.       (* = -3 : Z —— 一元负号在 Z 上才有 *)
Compute (Z.pow 2 10).  (* = 1024 : Z *)
Compute (2 - 5).       (* = 0 : nat —— 括号外默认仍是 nat *)
```

`%Z` 是**作用域限定符**：只在这对括号里，把数字和运算符解释成 Z 的。这是 Coq 处理「一个记号多种解释」的标准姿势——比全局 `Open Scope Z_scope.` 更可控（全局开作用域会让整个文件后面的 `2 + 3` 都变成 Z 加法，新手极易踩）。建议：**教学与小段代码用 `%Z` 局部限定；确实整段都是 Z 运算时再 Open Scope，并且 Open 在哪个 Module 里就只在哪个里生效**。

nat 与 Z 怎么选，第 22 章给决策表。现阶段记住一句话：**写证明用 nat（形状简单，归纳友好），做计算用 Z（二进制，快）**。

### 5.7 本章坑位清单（实测）

1. **`1 - 2 = 0`（截断减法）**：nat 无负数；依赖负中间结果的算法换 Z 或重排计算；
2. **`5 / 0 = 0`（除零静默）**：不崩溃、悄悄定义成 0，移植算法时警惕隐含假设；
3. **一堆记号默认不存在**：`/`、`mod`、`=?`、`<=?`、`<?`、`^` 都需要先 `Require Import Arith`；`&&`、`||` 需要 `Open Scope bool_scope`——裸环境只有 `+ - *` 和 `andb/orb/negb`（全部实测）；
4. **`if 1 then 2 else 3` 合法且 = 3**：if 是两构造子 match 的糖，nat 的 O/S 恰好符合——别被「条件必须 bool」的直觉骗了（5.5 节）；
5. **一元负号 `- 1` 在 nat 上不存在**：解析失败；负数去 `%Z`；
6. **`=?` `<=?` 是 bool 运算，`=` `<=` 是 Prop 关系**：混用会得到「类型不匹配」错误，看到 `?` 想到「可计算提问」。

---

## 第 6 章 元组与记录

对应示例：`examples/06_tuples_records.v`

### 6.1 积类型 A * B：把两个值捆成一个

有了「或」（变体/构造子），还要有「且」——把两个类型的值**同时**放在一起。这就是积类型：

```coq
Check (3, true).              (* (3, true) : nat * bool *)
Definition p : nat * bool := (3, true).
```

`nat * bool` 读作「一个 nat **和**一个 bool」。它只有一个构造方式：写一对 `(a, b)`。拆开用两个投影函数：

```coq
Compute (fst p).              (* = 3 : nat —— 第一个分量 *)
Compute (snd p).              (* = true : bool —— 第二个分量 *)
```

两个提醒：

1. 这里的 `*` 是 **type_scope 里的积类型记号**，与乘法无关（`Locate "*"` 会列出所有解释）。数学上「A 和 B 的所有组合」正是笛卡尔积，记号由此得名；
2. `fst`/`snd` 只拆**最外层**。嵌套元组 `(nat * nat) * bool` 要连用：`fst (fst q)`。连续投影很快变得难读——这正是下一节 `let` 解构和 Record 存在的理由。

### 6.2 let 解构：给分量起名字

```coq
Compute (let (x, y) := p in if y then x else 0).   (* = 3 *)
```

`let (x, y) := p in ...` 把 p 拆成 x 和 y 再用——一次解构任意深度，比 `fst (fst ...)` 可读得多。嵌套照写：`let (a, (b, c)) := q in a + b + c`。

它和第 7 章的 match 一脉相承（`let (x, y) := e in body` 本质是 `match e with (x, y) => body end`），差别只是积类型**只有一个构造子**，无需多分支。

### 6.3 Record：带字段名的积类型

当元组超过两三元、或分量语义重要时，用 Record：

```coq
Record Point : Type := {
  px : nat;
  py : nat
}.
```

读法：定义类型 `Point`，它有 `px`、`py` 两个 **nat 类型的字段**。构造用 `{| 字段 := 值; ... |}`：

```coq
Definition origin : Point := {| px := 0; py := 0 |}.
Definition p1 : Point := {| px := 2; py := 5 |}.
```

字段名同时就是**投影函数**：

```coq
Compute (px p1).              (* = 2 *)
Compute (py p1).              (* = 5 *)
```

改「某个字段」没有原地修改（Coq 数据不可变）——造一个新值：

```coq
Definition move_x (p : Point) (dx : nat) : Point :=
  {| px := px p + dx; py := py p |}.

Example move_ex : move_x p1 3 = {| px := 5; py := 5 |}.
Proof. reflexivity. Qed.
```

### 6.4 Record 的真身：单构造子归纳类型

用 Print 揭底（实测）：

```coq
Print Point.
(* Inductive Point : Type := Build_Point : nat -> nat -> Point *)
```

Record 完全不是新机制——它就是一个**只有一个构造子**（自动命名 `Build_Point`）的 Inductive，字段名是给投影函数起的别名。所以第 9 章的一切（归纳原理、构造子纪律）对 Record 照样适用。反过来，理解了这一点，「参数化 Record」也不神秘：

```coq
Record Trio (A : Type) : Type := {
  first : A;
  second : A;
  third : A
}.

Definition t1 : Trio nat := {| first := 1; second := 2; third := 3 |}.
Definition t2 : Trio bool := {| first := true; second := false; third := true |}.
```

一个实测坑：参数化 Record 的投影自带**显式类型参数**——裸写 `first t1` 会报错说 `t1` 应当是 `Type`（Coq 想让你先给 A）。两种解法：

```coq
Compute (first _ t1).         (* 下划线：让推断补 *)
Arguments first {A}.          (* 或把 A 设为隐式，一劳永逸 *)
Compute (first t1).           (* = 1 *)
```

### 6.5 元组还是 Record？

| 场景 | 选择 |
|---|---|
| 匿名小组合、当场拆掉 | 元组：`(nat * bool)`、函数返回「(结果, 是否成功)」 |
| 多于 2–3 个分量 | Record（位置记忆负担太大） |
| 分量会增删、要可读 | Record（按名访问，增删字段不破坏使用点） |
| 中间层 AST 节点 | 常直接多参数构造子（第 19 章） |

### 6.6 本章坑位清单（实测）

1. **`fst`/`snd` 只拆最外层**：嵌套要 `fst (fst q)` 连用，改用 `let (a, (b, c)) := ...`；
2. **字段名全局唯一**：两个 Record 不能有同名字段，第二个直接报 `fx already exists`——字段是全局命名空间里的投影函数，命名要带前缀意识（`px`/`py` 而不是裸 `x`/`y`）；
3. **参数化 Record 投影带显式类型参数**：`first t1` 报错，要 `first _ t1` 或 `Arguments first {A}`；
4. **`A * B` 的 `*` 不是乘法**：作用域决定含义（第 5 章 5.1 节）。

---

## 第 7 章 模式匹配

对应示例：`examples/07_patterns.v`

### 7.1 match：按形状分支

第 5 章说过 if 是「两构造子 match 的糖」。现在看正版：

```coq
Definition is_zero (n : nat) : bool :=
  match n with
  | O => true
  | S _ => false      (* S 后面的分量用通配符 _ 忽略 *)
  end.
```

读法：拿 n 的**形状**和每个分支的模式比对，用第一个匹配的分支。`O` 是构造子模式（零）；`S _` 是「S 套着任何东西」——下划线是通配符，绑定但不使用。

match 是 Coq 数据处理的**唯一**分支原语（if、let 解构都是它的糖衣）。它同时做三件事：

1. **测试**：值是哪个构造子造的？
2. **拆解**：把构造子的参数绑定到模式变量；
3. **保证穷尽**：编译器检查所有构造子都有分支。

第 3 条是 Coq 相对 C/Java switch 的本质优势：**你新加一个构造子，所有漏掉它的 match 当场编译失败**——重构的安全网。

### 7.2 模式词汇表

```coq
Definition classify (n : nat) : nat :=
  match n with
  | 0 => 0             (* 字面量 0 —— 就是 O *)
  | 1 => 1             (* 字面量 1 —— 就是 S O *)
  | 2 => 2
  | S (S (S _)) => 3   (* 嵌套模式：≥ 3 *)
  end.
```

| 模式 | 写法 | 作用 |
|---|---|---|
| 构造子 | `O`、`S k`、`Some x` | 匹配该构造子并拆参数 |
| 变量 | `k`、`x` | 匹配任意值并绑定（可使用） |
| 通配符 | `_` | 匹配任意值、不绑定 |
| 字面量 | `0`、`1`、`2` | 构造子的数字记号（nat 专用糖） |
| 元组 | `(a, b)` | 拆积类型 |
| 嵌套 | `S (S (S _))`、`_ :: y :: _` | 一次拆多层 |
| 多 scrutinee | `match a, b with \| true, true => ...` | 同时匹配多个值 |

两个细节：

- **字面量模式能到多深？** `2` 可以（S (S O)），但只能用于「小数字」——它就是记号展开，写 `| 5 => ...` 完全合法，Coq 会展开成 `S (S (S (S (S O))))`；
- **or 模式（`| A \| B => ...`）在 Coq 核心语法里不存在**（OCaml/Haskell 有）。想合并分支只能重复写或用通配符放宽——这是从那两门语言过来的一个真实不便。

### 7.3 嵌套与多 scrutinee

列表的「第二个元素」用嵌套模式一步到位：

```coq
Definition second (xs : list nat) : option nat :=
  match xs with
  | _ :: y :: _ => Some y    (* 至少两个元素，取第二个 *)
  | _ => None
  end.
```

一次匹配两个值（bool 的「与」）：

```coq
Definition both (b1 b2 : bool) : bool :=
  match b1, b2 with
  | true, true => true
  | _, _ => false
  end.
```

元组解构在 match 里最自然：

```coq
Definition add3 (p : nat * (nat * nat)) : nat :=
  match p with
  | (a, (b, c)) => a + b + c
  end.
```

### 7.4 穷尽性：漏分支 = 编译错误（实测）

```coq
Fail Definition missing (b : bool) : nat :=
  match b with
  | true => 1
  end.
(* Non exhaustive pattern-matching: no clause found for pattern "false" *)
```

错误信息直接**点名缺哪个构造子**。反过来说：只要编译通过，就没有「忘了处理某种情况」这类 bug——这一保证贯穿全书，是 Coq 值得忍受「啰嗦」的头号回报。

### 7.5 冗余分支：也是编译错误（实测，8.20）

写多了同样不行：

```coq
Fail Definition redundant (b : bool) : nat :=
  match b with
  | true => 1
  | false => 2
  | _ => 3       (* 前两支已覆盖全部 —— 这支永不可达 *)
  end.
(* Pattern "_" is redundant in this clause. *)
```

死分支是错误不是警告。好处：读代码时**每个分支都可信**，不存在「其实永远走不到」的暗桩；代价：合并分支时得留心顺序（先具体后宽泛，通配符只能垫底）。

### 7.6 match 是表达式

match 有值、有类型，可以出现在任何表达式位置：

```coq
Compute (match 3 with 0 => 0 | S _ => 1 end).   (* = 1 *)
```

没有「语句版 match」，不存在 break/fallthrough（C 的 switch 两大事故源在类型层面根除）。所有分支必须返回**同一类型**——`| true => 1 | false => "x"` 会报类型不匹配，把「分支结果类型不一致」从运行时隐患变成编译期错误。

### 7.7 模式变量与遮蔽

分支里绑定的变量**遮蔽**（shadow）外层同名变量：

```coq
Definition f (n : nat) : nat :=
  match n with
  | S n => n      (* 这个 n 是 S 拆出来的分量，不是外层参数 *)
  | O => 0
  end.
```

合法但可读性差，本教程不这么写。命名习惯：模式变量用新名字（`k`、`tl`、`rest`），与外层区分。

### 7.8 本章坑位清单（实测）

1. **漏分支**：`Non exhaustive pattern-matching`——错误信息会指出缺的构造子，补上即可；
2. **冗余分支**：`Pattern "..." is redundant in this clause`——8.20 里是错误不是警告；分支从具体到宽泛排，`_` 垫底；
3. **没有 or 模式**：`| x | y => ...` 写不了，与 OCaml/Haskell 不同；
4. **模式变量遮蔽外层**：合法但易错，改用新名字；
5. **分支类型不一致**：所有分支必须同类型，混搭是编译错误（这通常是好事）。

---

## 第 8 章 列表

对应示例：`examples/08_lists.v`

### 8.1 list 的真身：和 nat 同一个设计

```coq
Print list.
(* Inductive list (A : Type) : Type :=
     nil : list A | cons : A -> list A -> list A. *)
```

`list A` 是**参数化归纳类型**：装什么由 A 决定；它恰好两个构造子——`nil`（空表）和 `cons`（头接尾）。和 nat 的 `O`/`S` 一一对应：nat 是「一维的链」，list 是「每个结点还带一个 A 值的链」。这个同构不是巧合——凡「归纳」结构（链、树）都长这样，第 12 章的归纳证明对它们一视同仁。

书写用记号（**必须** `Import ListNotations`，见坑 1）：

```coq
Check (1 :: 2 :: nil).        (* [1; 2] : list nat *)
```

`[1; 2; 3]` 是 `cons 1 (cons 2 (cons 3 nil))` 的糖。打印时 Coq 也用记号显示。

### 8.2 标准库常用操作

全部实测：

| 操作 | 例子 | 结果 |
|---|---|---|
| 长度 | `length [1;2;3]` | `3` |
| 拼接 | `[1;2] ++ [3;4]` | `[1;2;3;4]` |
| 反转 | `rev [1;2;3]` | `[3;2;1]` |
| 拍平 | `concat [[1;2];[3]]` | `[1;2;3]` |
| 区间 | `seq 0 5` | `[0;1;2;3;4]` |
| 映射 | `map (fun n => n*2) [1;2;3]` | `[2;4;6]` |
| 过滤 | `filter (fun n => Nat.eqb (n mod 2) 0) [1;2;3;4]` | `[2;4]` |
| 取第 n 个 | `nth 1 [10;20;30] 0` | `20` |
| 求和 | `fold_right Nat.add 0 [1;2;3;4]` | `10` |

`nth` 的第三个参数是**越界默认值**：

```coq
Compute (nth 5 [10; 20; 30] 0).   (* = 0 —— 越界，静默返回默认值 *)
```

不崩溃，但也不报警——和 `5 / 0 = 0` 一个家族的坑（第 5 章）。要「显式失败」的语义，用返回 option 的版本（`nth_error`，第 17 章）。

### 8.3 自己写一遍：结构递归

理解列表操作最好的方式是亲手写。长度与拼接：

```coq
Fixpoint my_length {A : Type} (xs : list A) : nat :=
  match xs with
  | [] => 0
  | _ :: tl => S (my_length tl)      (* 一层剥掉一个头，长度加一 *)
  end.

Fixpoint my_append {A : Type} (xs ys : list A) : list A :=
  match xs with
  | [] => ys                         (* 空表拼任何表 = 那个表 *)
  | h :: tl => h :: my_append tl ys  (* 头保住，尾继续拼 *)
  end.

Example my_append_ex : my_append [1; 2] [3; 4] = [1; 2; 3; 4].
Proof. reflexivity. Qed.
```

注意两个函数的共同形状：**match 第一个参数、在 `tl`（严格子项）上递归、nil 给基础情形**——这就是第 10 章讲的「结构递归」，也是第 12 章归纳证明能对它们工作的原因。`{A : Type}` 隐式参数让它们天然多态（`my_length [true]` 照样工作）。

`safe_head` 展示了「拿不到值就明说」的建模：

```coq
Definition safe_head {A : Type} (xs : list A) : option A :=
  match xs with
  | [] => None
  | h :: _ => Some h
  end.
```

为什么不用 `nth xs 0 默认值`？因为**默认值会撒谎**（空表和「头恰好是默认值」无法区分）。option 是第 17 章的主题。

### 8.4 fold：方向与参数顺序（两个大坑，实测）

折叠（fold/reduce）是列表操作的「归一化」：一切「遍历列表攒一个结果」都能写成 fold。标准库给了两个方向：

```coq
(* fold_right f 初值 列表：从右往左叠 *)
Compute (fold_right Nat.add 0 [1; 2; 3; 4]).   (* = 10 *)
(* 展开形状：f 1 (f 2 (f 3 (f 4 初值))) *)

(* fold_left f 列表 初值：从左往右叠 —— 注意列表在前！ *)
Compute (fold_left Nat.add [1; 2; 3; 4] 0).    (* = 10 *)
(* 展开形状：f (f (f (f 初值 1) 2) 3) 4 *)
```

**坑一（参数顺序）**：`fold_right f a0 l` 是「f、初值、列表」，`fold_left f l a0` 是「f、**列表**、初值」——两个 fold 参数顺序不同！把初值放错位置不会报类型错误（fold_left 会把你的初值当列表折叠、把列表当初值返回），只会得到悄悄错误的结果（实测：`fold_left (fun acc x => x :: acc) [] [1;2;3]` 返回 `[1;2;3]`——它折叠的是空表）。

**坑二（方向差异）**：叠法不可交换时，两个 fold 结果不同。用一个「把元素 cons 到结果前」的叠法显形：

```coq
Compute (fold_right (fun x acc => x :: acc) [] [1; 2; 3]).
                                      (* = [1;2;3] *)
Compute (fold_left (fun acc x => x :: acc) [1; 2; 3] []).
                                      (* = [3;2;1] —— 恰好是 rev！ *)
```

注意两个 lambda 的参数顺序也不同（fold_right 是 `元素 续果`，fold_left 是 `积累 元素`）——方向、参数序两套差异要一起记。加法这种交换叠法无所谓；cons、减法、字符串拼接都必须选对方向。

### 8.5 证明预告

列表是第一个「值得证明」的结构。三个经典定律，第 20 章全部证一遍：

```coq
(* app_nil_r  : forall xs, xs ++ [] = xs          （看似显然，需归纳） *)
(* app_assoc  : forall xs ys zs, xs ++ ys ++ zs = (xs ++ ys) ++ zs *)
(* length_app : forall xs ys, length (xs ++ ys) = length xs + length ys *)
```

「显然」在 Coq 里必须变成归纳——而这正是训练的起点。

### 8.6 本章坑位清单（实测）

1. **`[1; 2]` 记号默认不存在**：必须 `From Coq Require Import List.` + `Import ListNotations.`，否则 `[` 直接语法错误。新手第一大坑；
2. **fold_left/fold_right 参数顺序不同**：`fold_left f l a0` vs `fold_right f a0 l`——初值位置互换，放错**不报错**只给错结果；
3. **`nth` 越界静默返回默认值**：默认值会掩盖「列表太短」的事实；要显式失败用 `nth_error`（option 版）；
4. **`++` 是右结合**：`[1] ++ [2] ++ [3]` = `[1] ++ ([2] ++ [3])`——对拼接无感（结合律成立），但换成别的右结合运算时要意识到求值形状；
5. **`::` 只能头插单个元素**：拼整表用 `++`；`x :: [1;2]` 合法而 `xs :: [1;2]`（xs 是表）类型错误。

---

## 第 9 章 归纳类型：自定义数据

对应示例：`examples/09_inductive.v`

### 9.1 Inductive：Coq 的「结构声明」

前面八章用的 nat、bool、list、option 全是 `Inductive` 声明的。现在自己写。语法骨架：

```coq
Inductive 类型名 : Type :=
| 构造子1 : 参数 -> ... -> 类型名
| 构造子2 : ...
.
```

每个构造子描述一种「造值的方式」。**类型的全部值 = 从构造子有限次组合能造出的一切**——这句话是归纳类型的语义，也是「归纳」二字的意思。

### 9.2 第一个：枚举

```coq
Inductive day : Type :=
  | monday    : day
  | tuesday   : day
  | wednesday : day
  | thursday  : day
  | friday    : day
  | saturday  : day
  | sunday    : day.

Definition next_workday (d : day) : day :=
  match d with
  | monday    => tuesday
  | tuesday   => wednesday
  | wednesday => thursday
  | thursday  => friday
  | friday    => monday
  | saturday  => monday
  | sunday    => monday
  end.

Example test_next :
  next_workday (next_workday saturday) = tuesday.
Proof. reflexivity. Qed.
```

七个构造子、零参数——枚举类型。对它的 match 必须覆盖七天（穷尽性），漏一天编译失败。类型安全到此为止已经超出多数语言：**非法日期（如 `fridayt`）根本无法书写**。

### 9.3 重新发明 bool 与 nat

构造子可以**带参数**，参数类型可以是正在定义的类型自己——递归由此而来：

```coq
Inductive mybool : Type :=
  | mytrue  : mybool
  | myfalse : mybool.

Inductive mynat : Type :=
  | mzero  : mynat
  | msucc  : mynat -> mynat.    (* 吃自己的值 —— 递归！ *)
```

`mybool` 就是 bool，`mynat` 就是 nat——标准库的 nat 不是黑魔法，是你二十行内能自己写出的东西。在 mynat 上定义函数与在 nat 上完全同构：

```coq
Fixpoint mydouble (n : mynat) : mynat :=
  match n with
  | mzero => mzero
  | msucc k => msucc (msucc (mydouble k))
  end.

Example mydouble_two : mydouble (msucc (msucc mzero))
                     = msucc (msucc (msucc (msucc mzero))).
Proof. reflexivity. Qed.
```

（注意 `Fixpoint` 不是 `Definition`——递归函数必须用前者，见第 10 章。）

### 9.4 类型参数：多态二叉树

```coq
Inductive btree (A : Type) : Type :=
  | leaf : btree A
  | node : btree A -> A -> btree A -> btree A.
```

`A` 是**类型参数**（list 的 `A` 同款）：整个声明对任意 A 成立。构造子默认**显式**携带 A——`node nat leaf 1 leaf` 很啰嗦，习惯上声明完立刻隐式化：

```coq
Arguments leaf {A}.
Arguments node {A} l a r.

Definition t1 : btree nat := node (node leaf 1 leaf) 2 (node leaf 3 leaf).
Check (node leaf true leaf).      (* : btree bool —— 换个类型照常工作 *)
```

树上写函数，与链表同一套方法——match 递归构造子、子项上递归：

```coq
Fixpoint mirror {A : Type} (t : btree A) : btree A :=
  match t with
  | leaf => leaf
  | node l a r => node (mirror r) a (mirror l)
  end.

Example mirror_ex : mirror t1 = node (node leaf 3 leaf) 2 (node leaf 1 leaf).
Proof. reflexivity. Qed.
```

`mirror (mirror t) = t` 这类定律第 20 章的习题里会证。

### 9.5 自动生成的归纳原理

每个 Inductive 声明后，Coq 自动生成一个「归纳原理」——对该类型做归纳证明的许可证：

```coq
Check day_ind.
(* forall P : day -> Prop,
   P monday -> P tuesday -> ... -> P sunday ->
   forall d : day, P d *)
```

读法：要证「P 对每个 day 成立」，只需对七个构造子各证一次 P——枚举的「归纳」就是穷举。

```coq
Check btree_ind.
(* forall (A : Type) (P : btree A -> Prop),
   P leaf ->
   (forall b, P b -> forall a, forall b0, P b0 -> P (node b a b0)) ->
   forall b, P b *)
```

树的版本正是数学归纳法的结构推广：**证叶子 + （假设左右子树成立 ⇒ 证节点）⇒ 证一切树**。第 12 章 `induction` 策略幕后调用的就是这些自动生成的原理。现在只需记住：**声明即免费获得归纳原理**，这是 Inductive 与普通「struct/class」的本质区别。

### 9.6 构造子的三大纪律

1. **单射**：`S x = S y` 则 `x = y`（`node l a r = node l' a' r'` 则三分量各相等）；
2. **不相交**：`monday ≠ tuesday`、`O ≠ S k`、`nil ≠ cons ...`——不同构造子造的值永不相等；
3. **可判别**：任给一个值，它的构造子是哪个**可判定**——match 与 discriminate 由此成立。

第三条的威力预览——从「不同构造子相等」这个**矛盾前提**推出**任何结论**：

```coq
Example day_absurd : monday = tuesday -> 1 = 2.
Proof.
  intros H.
  discriminate H.
Qed.
```

`discriminate` 发现 H 的两边是不同构造子，逻辑系统内爆炸，任何目标随即成立（爆炸原理）。第 13 章正式讲。

### 9.7 本章坑位清单（实测）

1. **构造子的类型参数默认显式**：不写 `Arguments leaf {A}.` 就得写 `leaf nat`——自定义完立刻隐式化是习惯动作；
2. **递归函数写成 `Definition`**：报「mydouble 未在环境中找到」之类的引用错误——真正原因是 `Definition` 不允许递归，名字根本没注册；用 `Fixpoint`；
3. **构造子名全局唯一**：与字段名一样（第 6 章坑 2），`leaf` 定义过一次后第二个类型不能再用；
4. **声明末尾的句点**：`Inductive ... .` 的句点在最后一个构造子之后，漏了整段报语法错。

---

## 第 10 章 递归函数：Fixpoint 与终止性

对应示例：`examples/10_fixpoint.v`

### 10.1 Fixpoint：会检查终止的递归

Coq 里递归函数用 `Fixpoint` 声明：

```coq
Fixpoint sum_to (n : nat) : nat :=
  match n with
  | O => 0
  | S k => S k + sum_to k      (* k 是 S k 的直接子项 —— 合法 *)
  end.

Compute (sum_to 4).            (* = 10：4+3+2+1 *)
```

与 `Definition` 的唯一区别：`Fixpoint` 要求**递归调用发生在「结构更小」的子项上**，并由守卫检查器（guard condition）逐个验证。为什么这么严格？因为 Coq 的函数不仅是代码，还是**逻辑对象**——若允许不终止的递归，就能构造出假命题的证明，整个系统的一致性崩塌（这门课不展开，记住结论）。代价是某些「显然会停」的写法（如按 `n - 1` 递减的循环）会被拒，收益是**每个能编译的函数必然全函数**——数学上无懈可击。

### 10.2 {struct n}：告诉 Coq 在哪个参数上递归

多参数函数，Coq 自动猜递减参数，猜不中时手动指定：

```coq
Fixpoint power (base : nat) (exp : nat) : nat :=
  match exp with
  | O => 1
  | S e => base * power base e
  end.

Print power.
(* 打印里能看到 {struct exp} —— Coq 记录了「在 exp 上结构递归」 *)
```

需要手动写的形态：`Fixpoint f (a : nat) (b : nat) {struct b} : ...`。

### 10.3 守卫检查的真实边界（实测）

教科书的说法是「递归必须在子项上」。实测 8.20.1，边界比这微妙：

```coq
(* 竟然能通过！ *)
Fixpoint bad_sum (n : nat) : nat :=
  match n with
  | O => 0
  | S k => bad_sum (k - 1) + 1
  end.

Compute (bad_sum 3).   (* = 2 —— 注意不是 3：k=0 时 0-1 截断为 0 *)
```

为什么 `k - 1` 能过？**守卫检查器会「看穿」定义**：`k - 1` 是 `Nat.sub k 1`，把它展开后每个分支要么是常量要么是 k 的子项——「展开后全是子项」就算过关。同理 `Nat.pred k`、甚至 `Nat.pred (Nat.pred k)` 都能过（实测）。这也解释了它为什么真的终止。

但在**参数本身**上递归，无论怎么包都过不了：

```coq
Fail Fixpoint bad2 (n : nat) : nat :=
  match n with
  | O => 0
  | S k => bad2 (n - 1)
  end.
(* Recursive call to bad2 has principal argument equal to
   "n - 1" instead of "k". *)

Fail Fixpoint bad_loop (n : nat) : nat :=
  match n with
  | O => 0
  | S k => bad_loop n
  end.
```

报错把「主参数应该是什么」说得明明白白（`instead of "k"`）。**实用心法：在分支里递归就用模式变量（k、tl），别用外层参数（n、xs）**——按这条写，守卫检查几乎不会找麻烦。

### 10.4 真正需要「非结构递归」时怎么办

写快排、归并这种「递归一半再一半」的算法，`n / 2` 不是子项，直写会被拒。三条出路：

1. **换形状**：很多算法有结构递归的等价版本（在 `(l, r) = split xs` 的分量上递归——split 拆出的两个表是 xs 的「逻辑子项」，配合 `program fixpoint`/`Function` 可行但繁琐）；
2. **燃料（fuel）**：多传一个 nat 参数当「剩余步数」，结构递归在燃料上——证明时处理燃料传递的繁琐；
3. **良基递归**（`well-founded`）：用 `Program Fixpoint` 或 `Function` 声明「按度量递减」，Coq 生成额外子证明。

第 21 章的插入排序不需要这些（它在表尾/表头结构上递归）；良基递归超出本书范围，知道名词和适用场景即可。

### 10.5 累加器写法

尾递归形态的遍历，把「已处理部分」作为参数携带：

```coq
Fixpoint rev_acc {A : Type} (acc : list A) (xs : list A) : list A :=
  match xs with
  | [] => acc
  | h :: tl => rev_acc (h :: acc) tl    (* 递归在 tl 上 —— 合法 *)
  end.

Definition fast_rev {A : Type} (xs : list A) : list A :=
  rev_acc [] xs.

Compute (fast_rev [1; 2; 3]).   (* = [3;2;1] *)
```

注意递减依然靠 `tl`（结构子项）——累加器**不改变**终止性的判定方式，只改变「结果怎么攒」。`fast_rev xs = rev xs` 的证明（和「rev (rev xs) = xs」）在第 20 章。

### 10.6 互递归：with

两个函数互相调用，用 `with` 连接声明：

```coq
Fixpoint myeven (n : nat) : bool :=
  match n with
  | O => true
  | S k => myodd k
  end
with myodd (n : nat) : bool :=
  match n with
  | O => false
  | S k => myeven k
  end.

Compute (myeven 10).           (* = true *)
Compute (myodd 7).             (* = true *)
```

守卫检查跨 `with` 全体进行。第 15 章会把这个 bool 版与 Prop 版的偶数对照。

### 10.7 本章坑位清单（实测）

1. **`n - 1` 型递归**：直觉以为必被拒，实测 8.20.1 **能过**（检查器展开 `Nat.sub` 后视为子项）；但 `n - 1`（n 是参数本身）被拒——分支里递归用模式变量，别用外层参数；
2. **递归函数误用 `Definition`**：报「引用未找到」，真实原因是名字没注册；
3. **多参数猜错递减参数**：报 `Cannot guess decreasing argument of fix`——加 `{struct 参数名}`；
4. **`Fixpoint` 一行版忘句点**：`end.` 属于 match，`Fixpoint` 整体还要一个句点收尾——嵌套句点数清楚；
5. **指望尾递归优化**：Coq 不做 TCO，累加器写法是「逻辑上一次递归」，不是性能优化（性能要靠第 22 章的数系与抽取）。

---

## 第 11 章 证明状态与 tactic 机理

对应示例：`examples/11_proof_state.v`

前 10 章写的都是「普通程序」。从本章起，证明成为主角。好消息是：你不需要学什么新语言——证明只是换一种方式与同一个类型系统对话。

### 11.1 证明状态：一间只有一块黑板的小教室

`Proof.` 之后、`Qed.` 之前，Coq 维护着一个**证明状态**（proof state）：

```text
n : nat                    <- 上下文（context）：已知的假设
IH : n + 0 = n                就是「有这些证据」
============================  <- 分隔线
S n + 0 = S n              <- 目标（goal）：还要证的东西
```

理解证明就理解了这幅图：

- **上下文**是黑板上半部分——已经收下的变量和假设；
- **目标**是黑板下半部分——当前欠的债；
- **策略**（tactic）是擦黑板的动作：每条策略要么把目标化简，要么把目标拆成几个小目标，要么从上下文里取东西用；
- 目标全部消失，`Qed.` 就能封印；还剩目标就 `Qed.`，报 `Attempt to save an incomplete proof`。

这个模型叫**目标导向证明**（goal-directed proof）。你在写的不是「证明的最终形态」，而是「制造证明的过程脚本」——`Qed.` 时脚本被编译成一个证明项（第 3 章的 eq_refl 就是它的产物），交内核复查。

### 11.2 逐句看一个证明的状态演变

以全书最重要的定理为例（示例 11 的注释里有完整快照）：

```coq
Theorem plus_n_O : forall n : nat, n + 0 = n.
Proof.
  intros n.
  induction n as [| n IH].
  - reflexivity.
  - simpl.
    rewrite IH.
    reflexivity.
Qed.
```

逐句解读：

**`intros n.`**——把 `forall` 的变量收进上下文。forall 是「给你任意 n」（第 14 章会看到它就是函数类型），intros 就是收下这份「任意」：

```text
n : nat
============================
n + 0 = n
```

**`induction n as [| n IH].`**——在 n 上归纳。按 nat 的两个构造子，目标裂成两个：

```text
目标 1（基例）：
============================
0 + 0 = 0

目标 2（步例）：
n : nat
IH : n + 0 = n        <- 归纳假设（induction hypothesis）
============================
S n + 0 = S n
```

`as [| n IH]` 的方括号按构造子排列：第一个 `|` 前是 O 的（无参数，空）；后面是 S 的两个参数——拆出的前驱叫 `n`，白送的「前驱定理」叫 `IH`。

**`- reflexivity.`**——子弹 `-` 点名处理第一个目标。`0 + 0` 按定义算出 `0`，两边一样，关闭。

**`- simpl.`**——处理第二个目标，先把 `S n + 0` 按 `Nat.add` 的定义展开一步（回忆：加法在第一个参数上递归，`S n + m = S (n + m)`）：

```text
S (n + 0) = S n
```

**`rewrite IH.`**——用 IH 把目标里的 `n + 0` 替换成 `n`：

```text
S n = S n
```

**`reflexivity.`**——关闭最后一个目标。黑板干净，`Qed.` 封印。

整个过程一句话总结：**归纳 = 让 Coq 按数据形状把定理拆成有限个小目标，基例靠计算，步例靠归纳假设**。

### 11.3 子弹：多目标的纪律

目标多于一个时，用**子弹**（bullets）逐个点名：第一层 `-`，第二层 `+`，第三层 `*`：

```coq
- (* 目标 1 *)
  + (* 目标 1.1 *)
  + (* 目标 1.2 *)
- (* 目标 2 *)
```

规则简单粗暴：**开了子弹就必须用完**——每个目标都要被处理到，否则 `Qed.` 报错。这是「证明没有偷偷漏情况」的第一道保险（第二道是穷尽性检查，第 7 章）。三层嵌套已经接近可读性极限，再深就该用 `assert` 先抽引理（第 18 章）。

不用子弹行不行？行——策略按顺序作用于「当前第一个目标」也能证完。但那样读证明的人（包括三个月后的你）无法确认哪些策略服务哪个目标。**本教程一律用子弹。**

### 11.4 apply 与 exact：调用现成的定理

已证过的定理是可复用的资产。两种用法：

```coq
Check Nat.add_0_r.            (* forall n : nat, n + 0 = n —— 库里早就有 *)

Example apply_demo : forall n : nat, n + 0 = n.
Proof.
  intros n.
  apply Nat.add_0_r.
Qed.

Example exact_demo : forall n : nat, n + 0 = n.
Proof.
  intros n.
  exact (Nat.add_0_r n).
Qed.
```

- **`apply 定理`**：把目标与定理**结论**对齐，自动补全参数，然后把定理的**前提**变成新目标——「用这条定理就能解决目标，前提你来还」。目标 `n + 0 = n` 正是 `Nat.add_0_r` 的结论（代入 ?n := n），无前提，一步关闭；
- **`exact 项`**：不做任何推理，把你给的项原样交出，类型必须与目标一字不差。`exact (Nat.add_0_r n)` 交的就是「把 n 代入后的那条定理」。

日常写法：apply 为主（省心），exact 用于「我知道答案就是它」的收尾。`apply` 是本章五虎将（intros / simpl / rewrite / reflexivity + apply）里唯一「反方向」工作的：它从结论倒推前提，这正是目标导向证明的引擎。

### 11.5 策略是可组合的元语言

一个提醒：tactic 不是 Coq 的核心语言，而是**操纵证明状态的元语言**。证据：同一个定理可以有无限多种脚本（多打一枪 `simpl`、换个方向 rewrite、先 destruct 再……），但 `Qed.` 后得到的证明项只有一个（`Print` 看看）。脚本的好坏只影响你的时间和可读性，不影响定理的可靠性——**可靠性由内核对最终证明项的检查保证**。

这也解释了为什么策略可以有副作用很重的自动化（第 18 章的 auto）：哪怕自动化生成了错误的中间步骤，内核也会在 Qed 时拒绝。分层信任，处处皆然。

### 11.6 实战节奏建议

初学者最有效的练习循环（CoqIDE / VSCoq 里）：

1. 写下 `Theorem ... ` + `Proof.`，看目标；
2. 每打一条策略，**看状态怎么变**——尤其是上下文多了什么、目标变成什么；
3. 卡住时依次自问：目标能不能 `simpl`？上下文里有没有能 `rewrite` 的？目标是不是某定理的结论（`apply`）？要不要分情况（`destruct`）/ 归纳（`induction`）？
4. 用 `Show.` 重看当前状态，`Search` 找形状匹配的定理。

把示例 11 在 CoqIDE 里逐步执行一遍，对照注释里的状态快照——这是本章唯一布置的「作业」。

### 11.7 本章坑位清单（实测）

1. **`Qed.` 时才报「没证完」**：错误定位在 Qed，病因在前面；养成子弹+`Show.` 的习惯；
2. **子弹层级混用**：同一层必须用同一符号（全 `-` 或全 `+`），混用报错；
3. **`induction` 前 `intros` 掉要归纳的变量**：先 `intros n` 再 `induction n` 没问题，但 `intros` 把依赖 n 的假设也收进来后，归纳时那些假设**不会被一般化**（进阶话题，第 20 章撞到再讲，先记住：要归纳的变量尽量最后 intros）；
4. **`apply` 方向不匹配**：目标是 `n = n + 0` 而定理结论是 `n + 0 = n` 时 apply 失败——先 `symmetry.` 转身（第 13 章）；
5. **策略名打错**：`simplfy`、`rewrtie`——报 `No such tactic`，拼写检查。

---

## 第 12 章 归纳证明

对应示例：`examples/12_induction.v`

### 12.1 为什么「显然」不够

`n + 0 = n`——「加法单位元，显然」。但在 Coq 里，`+` 是一个在第一个参数上递归的函数：`0 + m` 一步化简到 `m`（左边是 O，直接返回右边），而 `n + 0` 呢？左边是变量，`Nat.add` 的定义动不了它。**「显然」依赖的是数学知识，不是符号计算**——所以必须归纳。这恰是 Coq 的教学价值：它逼你把每个「显然」背后的原理（归纳）真正用出来。

### 12.2 归纳证明的通用剧本

第 11 章已经走过一遍，这里给出可背诵的模板：

```coq
Theorem T : forall n : nat, P n.
Proof.
  intros n. induction n as [| n IH].
  - reflexivity.                    (* 基例：算出来 *)
  - simpl. rewrite IH. reflexivity. (* 步例：展开、用 IH、收尾 *)
Qed.
```

三步：**分裂（induction）、算基例（reflexivity）、用假设（rewrite + reflexivity）**。适用面极广——nat、list、btree、任何归纳类型都行，因为 `induction` 幕后用的正是声明类型时自动生成的归纳原理（第 9 章的 `day_ind`、`btree_ind`）。

### 12.3 例 2：交换律——真实的工作量

```coq
Theorem plus_comm : forall n m : nat, n + m = m + n.
Proof.
  intros n m. induction n as [| n IH].
  - simpl. rewrite plus_n_O. reflexivity.
  - simpl. rewrite IH. rewrite plus_n_Sm. reflexivity.
Qed.
```

两个新情况，极具代表性：

**基例不是纯计算**：化简后是 `m = m + 0`——右边又是那个「动不了的 n + 0」！需要引理帮忙。这里 `rewrite plus_n_O` 用的是**本章自己证的定理**（方向 `n + 0 = n`），把 `m + 0` 替换成 `m`。

> 坑（实测）：标准库也有个 `plus_n_O`，但方向是 `n = n + 0`（反的！）。同名定理、方向不同，`rewrite` 的行为天差地别——**rewrite 之前先 `Check` 一下方向**是省时间的习惯。另外让「要找的一侧」是复合模式（`n + 0`）而不是裸变量，匹配才唯一（第 13 章展开）。

**步例需要「挪动 S」的引理**：`rewrite IH` 后目标是 `S (m + n) = m + S n`，两边各差一个 S 的位置。`plus_n_Sm : S (n + m) = n + S m` 正好搬运 S。

工作流建议：这些「搬运算子」的小引理**先 Search 再自证**（`Search (S _ + _)`、`Search (_ + S _)`），库里多半有；确实没有再手证，手证时它们往往又是一个普通归纳。

### 12.4 例 3：自定义函数的定律

对自己写的函数，同样套路：

```coq
Fixpoint double (n : nat) : nat :=
  match n with
  | O => O
  | S k => S (S (double k))
  end.

Theorem double_plus : forall n : nat, double n = n + n.
Proof.
  induction n as [| n IH].
  - reflexivity.
  - simpl. rewrite IH. rewrite <- plus_n_Sm. reflexivity.
Qed.
```

注意 `rewrite <- plus_n_Sm` 的**反向**使用：`plus_n_Sm` 把 `S (n + m)` 变成 `n + S m`，而这里需要把 `n + S n` 变回 `S (n + n)`——方向反着用。**rewrite 的方向感是本阶段最重要的肌肉记忆**，判断法：看你想消掉的模式在哪一侧。

### 12.5 例 4：列表上归纳——方法完全相同

```coq
Fixpoint my_append {A : Type} (xs ys : list A) : list A :=
  match xs with
  | [] => ys
  | h :: tl => h :: my_append tl ys
  end.

Theorem my_app_nil_r : forall (A : Type) (xs : list A),
  my_append xs [] = xs.
Proof.
  intros A xs. induction xs as [| x tl IH].
  - reflexivity.                    (* 空表拼空表 = 空表 *)
  - simpl. rewrite IH. reflexivity. (* 头保住，尾交给 IH *)
Qed.
```

和 nat 的归纳**零差别**：裂成 `[]` / `::` 两个情形，基例计算，步例用 IH。为什么 `my_append [] ys = ys` 这个「左单位元」不用证（`reflexivity` 就收）而「右单位元」要归纳？因为定义在**第一个参数**上 match——左边是 `[]` 一步化简，右边是变量动不了。**「证明的难度分布由定义的形状决定」**，这是写可证代码的第一直觉。

### 12.6 归纳的适用边界

| 想证的东西 | 用什么 |
|---|---|
| 具体数值断言 `3 + 4 = 7` | `reflexivity`（纯计算） |
| 对所有 n 的性质，函数按结构递归 | `induction`（本章） |
| 有限种情况（bool、枚举） | `destruct`（第 13 章，无 IH 的轻量归纳） |
| 「存在性/任意性」陈述 | 谓词逻辑工具（第 15 章） |

### 12.7 本章坑位清单（实测）

1. **同名定理方向相反**：本章 `plus_n_O`（n + 0 = n）与标准库 `plus_n_O`（n = n + 0）同姓不同向——rewrite 前 `Check`；
2. **归纳前把假设 intros 太多**：依赖被归纳变量的假设收进上下文后不参与一般化，步例的 IH 变弱甚至证不动（第 20 章有实例与解法 `revert`）；**口诀：要归纳的变量最后 intros**；
3. **忘记 `simpl` 直接 rewrite**：目标还是 `S n + 0` 的形状而 IH 谈的是 `n + 0`，rewrite 匹配不上——先 simpl 把形状展开；
4. **基例目标里残留变量**：`0 + m = m + 0` 的 m + 0 消不掉——Search 搬运算子方向的引理（`plus_n_O` / `Nat.add_0_r`）；
5. **induction 的 as 模式漏写**：默认给步例的假设起名 `IHn`——名字能用，但 `as [| n IH]` 显式命名后 rewrite 才顺手。

---

## 第 13 章 重写、化简与分情况讨论

对应示例：`examples/13_rewrite.v`

前两章的证明只用了五种策略。本章补齐日常证明的另外几件兵器：`destruct`、`symmetry`/`transitivity`、`discriminate`/`injection`，并把 `rewrite` 的方向问题讲透。

### 13.1 rewrite 的方向与「哪侧好匹配」

`rewrite H` 把 H **左边**的模式替换成右边；`rewrite <- H` 反向。方向的选择标准：

> **让「你要找的那个模式」处在复合模式（有结构）的一侧。**

标准库给了绝佳的对照样本：

```coq
Check Nat.add_0_r.   (* forall n, n + 0 = n —— 左侧复合：找 n + 0 *)
Check plus_n_O.      (* forall n, n = n + 0 —— 左侧裸变量！ *)
```

- `rewrite Nat.add_0_r`（正向）：在目标里**找 `?x + 0`**、替换为 `?x`——匹配唯一，行为完全可预期；
- `rewrite plus_n_O`（正向）：要在目标里「找裸变量 ?x」——几乎任何子项都匹配得上，行为微妙（可能原地不动，也可能把每个 n 都膨胀成 n + 0，实测两种都遇到过）；
- `rewrite <- plus_n_O`（反向）：找的模式来自右侧 `?x + 0`——又是复合模式，干净。

实测案例（示例 13）：想把假设 `H : n + 0 = m` 里的 `n + 0` 消掉，写 `rewrite plus_n_O in H` 无声无息什么都没发生；换 `rewrite Nat.add_0_r in H` 或 `rewrite <- plus_n_O in H` 立刻成功。

```coq
Theorem rw_in : forall n m : nat, n + 0 = m -> n = m.
Proof.
  intros n m H.
  rewrite Nat.add_0_r in H.   (* 假设里的 n + 0 换成 n *)
  exact H.                    (* H : n = m，正好是目标 *)
Qed.
```

### 13.2 simpl：只算不猜

`simpl` 把目标里的函数应用按定义展开（第 11 章已见）。两个要点：

1. **它只做符号计算**：`0 + n` 能化（定义如此），`n + 0` 不能（定义在第一个参数递归）——证明的工作量分布由此决定（第 12.5 节）；
2. **它可以作用于假设**：`simpl in H` 把假设里的可计算部分也展开——第 15 章 `simpl in H` 后接 `discriminate` 是高频连招。

`simpl` 打多了无害（最多费点算力），打少了 rewrite 匹配不上模式。卡住时先 simpl 一下是零成本的尝试。

### 13.3 destruct：分情况讨论

不需要归纳假设时，用 `destruct`——「把变量按构造子裂开，每种情况一个目标」：

```coq
Theorem negb_involutive : forall b : bool, negb (negb b) = b.
Proof.
  intros b. destruct b.
  - reflexivity.   (* b := true *)
  - reflexivity.   (* b := false *)
Qed.
```

`destruct n`（nat）则裂成 `0` 与 `S k`。**destruct 与 induction 的关系**：induction = destruct + 自动附赠归纳假设 IH。枚举两三种情况够用 destruct；结论需要「对更小的同类值成立」就必须 induction。

destruct 也能作用于**假设**（假设是 `P \/ Q` 时裂出两个分支，第 14 章）——这与「对变量 destruct」是同一个动作：把一个项按它的构造子拆开。

### 13.4 symmetry 与 transitivity：等式的姿态

```coq
Theorem sym_ex : forall n m : nat, n = m -> m = n.
Proof.
  intros n m H. symmetry. exact H.
Qed.

Example chain_ex : 2 + 2 = 4.
Proof.
  transitivity (3 + 1).
  - reflexivity.
  - reflexivity.
Qed.
```

- **`symmetry`** 把目标 `a = b` 翻转成 `b = a`——手里证据方向与目标相反时的标准动作（apply 反向定理前常先转身）；
- **`transitivity t`** 把目标 `a = c` 裂成 `a = t` 与 `t = c`——需要中转站时用。日常频率不高，但 `<=` 类目标的「夹逼」证明全靠它。

### 13.5 discriminate 与 injection：构造子的纪律落到实处

第 9 章说过构造子「单射、不相交」。对应的策略：

**`discriminate H`**——H 两边是**不同构造子**（如 `0 = 1`、`[] = x :: xs`）时，H 是矛盾，用它关闭**任何**目标：

```coq
Theorem zero_neq_one : 0 <> 1.
Proof.
  intros H.            (* <> 展开为 0 = 1 -> False *)
  discriminate H.
Qed.

Theorem nil_neq_cons : forall (A : Type) (x : A) (xs : list A),
  [] <> x :: xs.
Proof.
  intros A x xs H. discriminate H.
Qed.
```

**`injection H`**——H 两边是**同一构造子**（如 `S n = S m`）时，提取「参数相等」的新假设：

```coq
Theorem inj_ex : forall n m : nat, S n = S m -> n = m.
Proof.
  intros n m H.
  injection H as H2.   (* 从 S n = S m 里抽出 n = m *)
  exact H2.
Qed.
```

两者合起来就是「构造子纪律」的可操作版本。经典应用是证**不可能的等式**（如 `S n <> n`）与从等式解构数据——第 15 章证 `evenb 1 = true -> even 1` 时，`simpl in H. discriminate H.` 一击毙命。

### 13.6 本章策略速查表

| 策略 | 作用对象 | 干什么 |
|---|---|---|
| `intros` | 目标的 forall/-> | 收变量/假设进上下文（可带解构模式） |
| `simpl`（`in H`） | 目标或假设 | 按定义展开计算 |
| `rewrite H`（`<-`/`in H`） | 目标或假设 | 按等式替换（注意方向，见 13.1） |
| `reflexivity` | 目标 | 两边可化简为同值即关闭 |
| `destruct x`（`as 模式`） | 变量或假设 | 按构造子分情况（无 IH） |
| `induction x` | 变量 | 分情况 + 赠送 IH |
| `apply 定理` | 目标 | 按结论对齐，前提变新目标 |
| `exact 项` | 目标 | 直接交出证明项 |
| `symmetry` | 目标 | 翻转等式 |
| `transitivity t` | 目标 | 拆两段等式 |
| `discriminate H` | 假设 | 不同构造子的等式 = 矛盾，关任何目标 |
| `injection H as H2` | 假设 | 同构造子等式 → 参数等式 |

这张表覆盖了 80% 的日常证明。第 18 章再补自动化与控制流。

### 13.7 本章坑位清单（实测）

1. **rewrite 裸变量方向**：定理一侧是裸变量时正向 rewrite 行为不稳定（可能没动作、可能膨胀）——用复合模式那侧，或反向（13.1 的实测案例）；
2. **`rewrite ... in H` 忘了 `in H`**：改了目标没改假设，还以为定理是错的——看清楚上下文里哪边需要变；
3. **discriminate 拿错东西**：`discriminate H` 要求 H 恰好是「不同构造子相等」；H 形如 `S n = S m` 时该用 injection；
4. **injection 之后忘 intro**：`injection H.` 不带 `as` 会把 `n = m` 放进目标（变成待 intro 的形式）——用 `injection H as H2` 直接收为假设更顺手；
5. **对 Prop 用 destruct**：`destruct` 只拆归纳类型；`~P` 是定义不是构造子，intro 模式进不去（第 14 章的实测坑）。

---

## 第 14 章 命题逻辑

对应示例：`examples/14_logic.v`

### 14.1 Prop 世界的数据结构

第 4 章埋的线现在收：`Prop` 住着命题。命题本身也是**归纳类型**，有自己的构造子：

| 写法 | 真身 | 构造子 | 证明它的策略 | 使用它的策略 |
|---|---|---|---|---|
| `P /\ Q`（且） | `and P Q` | `conj : P -> Q -> P /\ Q` | `split` | `destruct` |
| `P \/ Q`（或） | `or P Q` | `or_introl` / `or_intror` | `left` / `right` | `destruct` |
| `P -> Q`（蕴含） | 函数类型 | （就是函数） | `intros` | `apply` |
| `~ P`（非） | `not P := P -> False` | （就是函数） | `intros` | `apply` |
| `P <-> Q`（当且仅当） | `(P -> Q) /\ (Q -> P)` | （是合取） | `split` 后各证 | `destruct` |
| `True` | 单构造子 `I` | `I : True` | `exact I` | 无用武之地 |
| `False` | **无构造子** | （不存在） | （证不了） | `destruct`（爆炸） |

这张表是本章全部内容的压缩版。注意每个「证明它的策略」恰好是 Curry–Howard 的体现：**造值用构造子，拆值用 match（destruct），函数靠 apply**——Prop 世界与数据世界共用同一套规则，没有新东西。

### 14.2 合取：split 与 destruct

```coq
Theorem and_comm : forall P Q : Prop, P /\ Q -> Q /\ P.
Proof.
  intros P Q H.
  destruct H as [HP HQ].   (* 拆开「且」的假设：两个证据 *)
  split.                   (* 拆开「且」的目标：两个子目标 *)
  - exact HQ.
  - exact HP.
Qed.
```

读法与第 6 章的元组完全同构：`/\` 就像 `*`（积类型），`split` 造对偶，`destruct as [HP HQ]` 拆对偶。三层子弹的完整体验（`and_assoc`，交换结合顺序的接线练习）：

```coq
Theorem and_assoc : forall P Q R : Prop,
  (P /\ Q) /\ R <-> P /\ (Q /\ R).
Proof.
  intros P Q R. split.
  - intros [[HP HQ] HR]. split.
    + exact HP.
    + split.
      * exact HQ.
      * exact HR.
  - intros [HP [HQ HR]]. split.
    + split.
      * exact HP.
      * exact HQ.
    + exact HR.
Qed.
```

`intros [[HP HQ] HR]` 的嵌套模式一次拆到底（与 `let (a, (b, c)) := ...` 同款语法）。逻辑证明写多了你会发现：**一半的逻辑证明其实是「拆线再接线」的手工活**，模式匹配的熟练度直接决定速度。

### 14.3 析取：left / right 与带 | 的 destruct

```coq
Theorem or_comm : forall P Q : Prop, P \/ Q -> Q \/ P.
Proof.
  intros P Q H.
  destruct H as [HP | HQ].   (* 或：两个分支，走哪支拿哪支的证据 *)
  - right. exact HP.
  - left. exact HQ.
Qed.
```

- 目标是 `P \/ Q` 时，`left`/`right` **选择**你要证哪边（对应构造子 or_introl/or_intror）——注意这两个词与子弹毫无关系；
- 假设是 `P \/ Q` 时，`destruct as [HP | HQ]` 裂成两个分支——**竖线 | 就是「或」**，在 as 模式里含义完全一致（对比合取的 `[HP HQ]` 空格并排）。

析取像第 9 章的变体（sum 类型 `A + B` 的 Prop 版）——同构关系贯穿始终。

### 14.4 蕴含与否定：它们就是函数

**蕴含**在第 1 章就剧透过，现在正式编译它——注意这个证明**一个策略都不用**，直接写出函数：

```coq
Definition modus_ponens (P Q : Prop) (hpq : P -> Q) (hp : P) : Q :=
  hpq hp.
```

「P 蕴含 Q」的证明是函数；「肯定前件」（拿 P 的证明喂给它）就是函数应用。策略风格同一件事：

```coq
Theorem modus_ponens' (P Q : Prop) : (P -> Q) -> P -> Q.
Proof.
  intros hpq hp.    (* 蕴含的前提就是函数参数，intros 收下 *)
  apply hpq.        (* 目标 Q，hpq 造得出，前提 P 变新目标 *)
  exact hp.
Qed.
```

**否定**没有新东西——`Print not.` 揭底：

```coq
Print not.
(* not A := A -> False *)
```

`~P` 是「P 推出假」的缩写。所以证 `~P` 就是 `intros`（收下 P 的证明再构造 False）；用 `~P` 的证据就是 `apply`（把 P 喂给它，得到 False）。经典一例（P 与「非 P」不同时成立）：

```coq
Theorem not_and_true : forall P : Prop, ~ (P /\ ~ P).
Proof.
  intros P [HP HnP].
  (* 注意：~ P 不再往下解构——~ 是定义不是构造子，
     intro 模式进不去，直接收下当函数用（实测坑） *)
  apply HnP.        (* 目标 ~P 即 P -> False：喂个 P 进去 *)
  exact HP.
Qed.
```

### 14.5 True、False 与爆炸原理

- `True` 有唯一证明 `I`，随叫随到（`exact I`）——所以它当「免费赠品」出现在合取里（`P /\ True <-> P`）；
- `False` **没有构造子**——所以永远证不出它，但**假设里有它时什么都能证**：

```coq
Theorem from_false : forall P : Prop, False -> P.
Proof.
  intros P H. destruct H.   (* False 零构造子，destruct 无分支可走，
                               直接关闭任意目标 *)
Qed.
```

这就是**爆炸原理**（ex falso quodlibet）：从矛盾出发，一切皆可证。它与第 13 章的 `discriminate` 一脉相承——discriminate 本质是「发现矛盾假设 → 引爆」。`~P` 定义成 `P -> False` 的设计因此完全自洽：「非 P」=「P 能引爆整个系统」。

### 14.6 <->：一次 split，两个方向

`P <-> Q` 展开是 `(P -> Q) /\ (Q -> P)`——所以策略组合固定：`split` 后各证一个蕴含。示例 14 的 `and_true_iff`：

```coq
Theorem and_true_iff : forall P : Prop, P /\ True <-> P.
Proof.
  intros P. split.
  - intros [HP _]. exact HP.   (* _ 丢弃不需要的 I *)
  - intros HP. split.
    + exact HP.
    + exact I.
Qed.
```

写 iff 证明的节奏感：**先 split，两个方向各自独立作战**。命名习惯上方向叫「→ 方向」「← 方向」（或 forward/backward），与 `rewrite` 的方向用语一致。

### 14.7 经典逻辑 vs 构造逻辑（一段重要的题外话）

Coq 的逻辑是**构造逻辑**（intuitionistic）：证明 `P \/ Q` 必须给出**到底哪一边**——没有「排中律」`forall P, P \/ ~ P`（不添加公理的话）。这不是缺陷而是立场：

- 构造性证明**携带信息**：`P \/ ~P` 的构造性证明就是「判断 P 真假的算法」——对任意命题这种算法不存在；
- 需要经典推理时可以 `Require Import Classical`，引入排中律公理——代价是证明里多了公理依赖（`Print Assumptions` 会显示，第 23 章）。

初学阶段（也是本教程全程）**只用构造逻辑**，不碰 Classical。判断自己是否在「越界」的信号：想证 `~ ~ P -> P` 或 `P \/ ~ P`——这两个都是经典逻辑标志，构造逻辑里证不出。

### 14.8 本章坑位清单（实测）

1. **对 `~P` 用 intro 解构模式**：`intros [HP [HnP]]` 在 `~(P /\ ~P)` 上报 `Expects a disjunctive pattern with 0 branches`——`~` 是定义（函数），不是构造子，模式进不去；先 `intros P [HP HnP]` 拆到 `~P` 为止；
2. **left/right 与子弹混淆**：它们是「选构造子」，不是目标管理——嵌套时该用子弹还是用子弹；
3. **_iff 忘了 split**：直接对 `P <-> Q` 的目标 apply 单方向引理会失败——先 split；
4. **把 False 当成可证目标硬证**：证 `False` 只能靠上下文矛盾（destruct 假设 / discriminate）；
5. **试图证排中律**：构造逻辑里不可能；需要经典逻辑用 Classical 库并接受公理依赖。

---

## 第 15 章 谓词逻辑与 reflect

对应示例：`examples/15_predicates.v`

### 15.1 归纳谓词：命题也能带参数

`Inductive` 造的类型可以住在 `Prop` 里，且**结论可以依赖参数**——这叫归纳谓词：

```coq
Inductive even : nat -> Prop :=
  | even_O : even 0
  | even_SS : forall n : nat, even n -> even (S (S n)).
```

读法：「是偶数」由两条规则定义：0 是偶数；n 是偶数则 n+2 是偶数。**没有其他途径**——一个数是偶数，当且仅当它能被这两条规则有限次推导出来。

造证据像搭积木：

```coq
Example even_4 : even 4.
Proof.
  apply even_SS. apply even_SS. apply even_O.
Qed.
```

与 bool 的根本区别（第 4 章的伏笔正式揭晓）：

| | `evenb n`（bool） | `even n`（Prop） |
|---|---|---|
| 本质 | 程序，跑起来算 true/false | 命题，靠规则推导 |
| 用途 | 写代码时分支 | 陈述与证明数学性质 |
| 表达力 | 有限（具体值） | 无穷（forall/exists 随意组合） |
| 代价 | 不能直接用于推理 | 不能直接拿来计算 |

两套并存不是冗余——**分别服务「算」与「证」**，本章末尾的 reflect 把它们焊在一起。

### 15.2 证「函数保性质」：归纳谓词遇上归纳证明

```coq
Theorem even_double : forall n : nat, even (double n).
Proof.
  induction n as [| n IH].
  - apply even_O.
  - simpl. apply even_SS. exact IH.
Qed.
```

对 n 归纳（第 12 章套路），步例里 `apply even_SS` 把目标 `even (S (S (double n)))` 退回 `even (double n)`——apply 对**带参数的构造子**照样工作：目标与构造子结论对齐，剩余参数自动补全，前提 `even n` 变新目标。

### 15.3 对证据本身做归纳

真正的新武器：`induction` 可以作用在**证明**上：

```coq
Theorem even_evenb : forall n : nat, even n -> evenb n = true.
Proof.
  intros n H.
  induction H as [| n' Hev IH].
  - reflexivity.              (* evenb 0 = true *)
  - simpl. exact IH.          (* evenb (S (S n')) 化简就是 evenb n' *)
Qed.
```

`induction H`（H : even n 的证据）按 even 的两条规则分裂：基例对应 `even_O`；步例的 as 模式 `[| n' Hev IH]` 收下构造子的三样东西——参数 n'、子证据 Hev、归纳假设 IH（「even n' ⇒ 结论」）。**对规则的归纳**正是数学里「对推导结构归纳」的直译。

（此处的 `evenb` 是本章自定义的两步 bool 函数；标准库的 `Nat.even` 用取模实现，`simpl` 行为不直观，教学上自造的更清楚。）

### 15.4 存在量词 exists

```coq
Theorem even_exists_double : forall n : nat,
  even n -> exists k : nat, n = double k.
Proof.
  intros n H.
  induction H as [| n' Hev IH].
  - exists 0. reflexivity.
  - destruct IH as [k Hk].
    exists (S k). simpl. rewrite <- Hk. reflexivity.
Qed.
```

- **证 exists**：`exists 证人.`——把目标降级为「该证人满足性质」。选证人是你的活（这里选 S k）；
- **用 exists**：`destruct ... as [k Hk]`——拆出证人与性质。

Curry–Howard 视角：`forall` 是「任给 x 交付 P x」的函数（依赖函数类型），`exists` 是「证人与证明的打包」（依赖对偶 `{k : nat & n = double k}` 的 Prop 版）。两个量词都是**依赖类型**的日常形态——你已经用依赖类型编程半小时了。

### 15.5 强化命题：两步归纳（全书第一个「技巧」）

反向定理 `evenb_even : evenb n = true -> even n` 藏着经典陷阱。朴素做法 `induction n` 拿到的 IH 只谈**直接前驱** n'，而 `evenb (S (S n)) = evenb n` 谈的是**隔一代**的前驱——IH 够不着，证不动。

标准解法是本章标题级的内容——**把命题加强成两倍，再归纳**：

```coq
Lemma two_step : forall P : nat -> Prop,
  P 0 -> P 1 ->
  (forall n : nat, P n -> P (S (S n))) ->
  forall n : nat, P n.
Proof.
  intros P H0 H1 HSS.
  assert (Hboth : forall n : nat, P n /\ P (S n)).
  { induction n as [| n [IH1 IH2]].
    - split.
      + exact H0.
      + exact H1.
    - split.
      + exact IH2.
      + apply HSS. exact IH1. }
  intros n. destruct (Hboth n) as [Hn _]. exact Hn.
Qed.

Theorem evenb_even : forall n : nat, evenb n = true -> even n.
Proof.
  apply (two_step (fun n => evenb n = true -> even n)).
  - intros _. apply even_O.
  - intros H. simpl in H. discriminate H.   (* evenb 1 = false，矛盾 *)
  - intros n IH H. simpl in H. apply even_SS. apply IH. exact H.
Qed.
```

值得逐行品味：`P n /\ P (S n)`（「相邻两个都成立」）比 `P n`（「单个成立」）**更强**，但更强反而好证——归纳步从 `P (S n)` 和 `P n` 两块积木里拿料（IH2 当燃料，IH1 喂给 HSS）。这个模式叫**归纳强化**（strengthening the induction hypothesis），是归纳证明最重要的心法：**证不动时，别死磕——把命题改强**。第 20 章的 `rev` 定理会再次用到这个思想。

### 15.6 reflect：bool 与 Prop 的官方桥梁

两套世界需要频繁互通。标准库的方案是归纳类型 `reflect`：

```coq
Theorem evenb_reflect : forall n : nat, reflect (even n) (evenb n).
Proof.
  intros n.
  destruct (evenb n) eqn:E.          (* 按 evenb n 的值分情况，记住 E *)
  - apply ReflectT. apply evenb_even. exact E.
  - apply ReflectF.
    intros Hev.
    rewrite (even_evenb n Hev) in E. (* 两个世界的知识对流 *)
    discriminate E.
Qed.
```

`reflect P b` 打包了两个方向：`ReflectT`（b = true 且 P 成立）与 `ReflectF`（b = false 且 P 不成立）。有了它：

- **算出来再说**：运行期用 `evenb` 分支（高效），需要推理时用 reflect 定理换轨到 `even`；
- **一处封装，处处受益**：标准库对常用判定给的是 **iff 形态**的桥（实测：`Nat.eqb_eq : (n =? m) = true <-> n = m`、`Nat.leb_le : (n <=? m) = true <-> n <= m`，需 `Arith`）——reflect 是更结构化的同款思想，把「是/否」与「成立/不成立」各装一盒。

`destruct (evenb n) eqn:E` 的 `eqn:E` 是重要小技巧：分情况的同时**记住**等式 `evenb n = true/false`——之后 `rewrite ... in E` 让两个世界的证据对流，最后 `discriminate E` 引爆矛盾。这一套组合拳（destruct eqn / rewrite in / discriminate）是谓词证明的高频三连。

### 15.7 本章坑位清单（实测）

1. **归纳谓词的构造子不是函数**：`even_SS` 不能 `Compute`——它是逻辑规则不是程序；想要可计算版另写 bool 函数 + reflect 桥；
2. **朴素归纳证两步递归性质**：IH 只谈直接前驱，`evenb (S (S n))` 够不着——用 15.5 的强化技巧（`P n /\ P (S n)`）；
3. **`destruct (evenb n) eqn:E` 忘写 eqn:E**：分支里没有 `evenb n = ...` 的记录，后续想 rewrite 无从下手；
4. **exists 的证人选错**：`exists 0.` 之后目标降级为具体等式，选错证人只能 Abort 重来（没有「换证人」的策略，实际上可以 `clear` 后重来，但重新 exists 更直接）；
5. **标准库 `Nat.even` 的 simpl 不直观**（按取模实现）：教学与自造谓词配套时，bool 版也自造（本章 `evenb`），别混用。

---

## 第 16 章 高阶函数及其证明

对应示例：`examples/16_higher_order.v`

### 16.1 函数是一等值

前几章已经反复出现「函数当参数传」（map、filter、fold），现在正式立牌坊：**函数是值**——可以存进变量、当参数传、当结果返回、放进数据结构。以函数为参数/结果的函数叫**高阶函数**。

```coq
Definition apply_twice {A : Type} (f : A -> A) (x : A) : A :=
  f (f x).

Compute (apply_twice (fun n => n * 2) 5).   (* = 20 *)
```

高阶函数是复用的基本单位：`map` 一个定义覆盖「对每种数据各做一件事」的无限需求。而**组合**是高阶函数的代数：

```coq
Definition compose {A B C : Type} (f : B -> C) (g : A -> B) : A -> C :=
  fun x => f (g x).
```

「先 g 后 f」打包成一个新函数——数学记号 f∘g 的可执行版。

### 16.2 高阶函数的定律

高阶函数不止能跑，还能**证**。三条经典定律（示例 16 全部证毕）：

```coq
(* 融合律：两次 map 可合一次 *)
map_compose : map (compose f g) xs = map f (map g xs)

(* 长度保持：map 不丢不重 *)
map_length  : length (map f xs) = length xs

(* 幂等律：筛过的再筛不变 *)
filter_idem : filter p (filter p xs) = filter p xs
```

以融合律为例看证明——你期待的新东西一件都没有：

```coq
Theorem map_compose : forall (A B C : Type)
                                 (f : B -> C) (g : A -> B) (xs : list A),
  map (compose f g) xs = map f (map g xs).
Proof.
  intros A B C f g xs. induction xs as [| x tl IH].
  - reflexivity.
  - simpl. rewrite IH. reflexivity.
Qed.
```

对 xs 归纳、基例计算、步例用 IH——与第 12 章证 `n + 0 = n` 的剧本**一字不差**。「函数当参数」完全不改变证明形状，因为归纳发生在列表的结构上，而函数对结构一无所知。这是本章的核心信息：**数据决定证明，函数只是数据上的乘客**。

### 16.3 destruct eqn：对付 filter 的标准姿势

`filter_idem` 的证明藏着一个值得单说的技术：

```coq
Theorem filter_idem : forall (A : Type) (p : A -> bool) (xs : list A),
  filter p (filter p xs) = filter p xs.
Proof.
  intros A p xs. induction xs as [| x tl IH].
  - reflexivity.
  - simpl. destruct (p x) eqn:E.
    + simpl. rewrite E. rewrite IH. reflexivity.
    + exact IH.
Qed.
```

麻烦在于 `filter` 的定义里有 `if p x`：`simpl` 展开后 `p x` 卡在判断里（p 是变量，算不出）。`destruct (p x) eqn:E` 按它的值分情况——但注意**展开内层 filter 时 `if p x` 会再次出现**（第一次 destruct 替换的是当时可见的那处），所以再 `simpl` 暴露新的 `if` 后，要用 `E : p x = true` 来 `rewrite E` 消掉它。这套「**destruct eqn → simpl → rewrite E**」的连环是所有涉及 bool 判断的函数（filter、find、partition……）证明的通用解法，第 21 章排序证明会再次依赖它。

### 16.4 用 fold 造一切

`fold_right`（第 8 章）的威力值得再强调——它是一切「遍历攒结果」的归一形式：

```coq
Theorem fold_cons : forall (A : Type) (xs : list A),
  fold_right (fun x acc => x :: acc) [] xs = xs.
Proof.
  intros A xs. induction xs as [| x tl IH].
  - reflexivity.
  - simpl. rewrite IH. reflexivity.
Qed.
```

把 `cons` 本身当叠法，fold 就退化成恒等；换 `Nat.add` 是求和，换 `orb` 是存在判断，换 `(fun x acc => if p x then x :: acc else acc)` 是手写 filter。**理解一个 fold，等于理解一族函数**——这是函数式编程的复利。

### 16.5 本章坑位清单（实测）

1. **filter 展开后 `if` 复活**：`destruct (p x)` 一次不够，`eqn:E` + `rewrite E` 才能收干净（16.3 的完整演示）；
2. **对「函数相等」想当然**：`fun x => x + 0` 与 `fun x => x` 在 Coq 里**不能互推为相等**（函数外延性不是内建公理）——但两条**定律**（对任意输入结果相同）照证不误，本教程始终证定律；
3. **compose 的参数顺序**：`compose f g` 是先 g 后 f（与数学 f∘g 一致），写成「先 f 后 g」会证出反向定律，名字起清楚很重要。

---

## 第 17 章 Option：安全建模

对应示例：`examples/17_option.v`

### 17.1 用类型消灭一类错误

「查无此值」是程序错误的经典来源：空列表取头、字典查不存在的键、除以零。主流语言的方案——返回 NULL（C）、抛异常（Java）、返回 undefined（JS）——共同问题：**调用方可以装作不会失败**，类型系统不设防。

Coq 的方案是把「可能没有」编码进类型：

```coq
Inductive option (A : Type) : Type :=
  | Some : A -> option A
  | None : option A.
```

`option nat` 的每个值要么是 `Some n`（有货），要么是 `None`（没货）——**想拿到里面的 nat，必须 match，必须处理 None 分支**（穷尽性检查强制）。错误从「运行时意外」变成「编译期必须回答的问题」。对比第 8 章的 `nth`（越界静默给默认值——错误被吞），option 版干净得多：

```coq
Fixpoint nth_option {A : Type} (n : nat) (xs : list A) : option A :=
  match n, xs with
  | O, x :: _ => Some x
  | S k, _ :: tl => nth_option k tl
  | _, _ => None
  end.

Compute (nth_option 5 [10; 20; 30]).   (* = None —— 越界明说 *)
```

这个 match 的 `,` 双 scrutinee 语法第 7 章见过；`_, _` 兜底组合「越界」与「列表太短」两种失败。

### 17.2 option 上的三个基本操作

拿到 option 后的三种典型处理，全部是普通函数：

```coq
Definition option_map {A B : Type} (f : A -> B) (o : option A) : option B :=
  match o with
  | Some x => Some (f x)
  | None => None
  end.

Definition default {A : Type} (d : A) (o : option A) : A :=
  match o with
  | Some x => x
  | None => d
  end.

Definition bind {A B : Type} (o : option A) (f : A -> option B) : option B :=
  match o with
  | Some x => f x
  | None => None
  end.
```

- **`option_map`**：对有货的做变换，没货的原样传播失败——「成功的路径上加工」；
- **`default`**：显式兜底——「我现在必须要一个值，取不到就用这个」，把第 8 章 `nth` 隐式做的事变成明说；
- **`bind`**：串联可能失败的计算——上一步有货就喂给下一步，没货整个链条直接 None（这就是 monad 的 `bind`，不用记名词，记住行为）。

### 17.3 链式：安全除法流水线

实战看效果——「取列表前两个元素相除」，任何一步失败整体就 None：

```coq
Definition safe_div (a b : nat) : option nat :=
  if Nat.eqb b 0 then None else Some (a / b).

Definition div_heads (xs : list nat) : option nat :=
  bind (nth_option 0 xs) (fun a =>
    bind (nth_option 1 xs) (fun b => safe_div a b)).

Compute (div_heads [10; 2]).    (* = Some 5 *)
Compute (div_heads [10]).       (* = None —— 第二个元素不存在 *)
Compute (div_heads [10; 0]).    (* = None —— 除零 *)
```

对照命令式写法（取头、判空、取次、判空、判除零……），bind 版把「失败传播」的样板全部收进一个组合子，业务逻辑一行陈述。这正是 Rust 的 `?`、Swift 的可选链、Haskell 的 Maybe monad 同款思想——**Coq 里它只是个普通函数**。

### 17.4 option 的定律

option 同样有可证的定律（示例 17）：

```coq
Theorem option_map_id : forall (A : Type) (o : option A),
  option_map (fun x => x) o = o.
Proof.
  intros A o. destruct o.
  - reflexivity.
  - reflexivity.
Qed.
```

对 o 分情况（Some/None）——**不需要归纳**（option 不是递归类型，没有「更小的 option」）。这提示一条选择法则：数据是一层还是多层，决定 destruct 还是 induction。

更有营养的是 `nth_option` 与 `map` 的交换律（对第 n 个取值，先后做 map 结果一样）：

```coq
Theorem nth_option_map : forall (A B : Type) (f : A -> B)
                                   (n : nat) (xs : list A),
  option_map f (nth_option n xs) = nth_option n (map f xs).
Proof.
  intros A B f n. induction n as [| n IH]; intros xs.
  - destruct xs as [| x tl].
    + reflexivity.
    + reflexivity.
  - destruct xs as [| x tl].
    + reflexivity.
    + simpl. apply IH.
Qed.
```

注意结构：**对 n 归纳、对 xs 分情况**——两个维度各司其职。以及一个重要的细节：`intros xs` 放在 `induction n` **之后**——归纳时 xs 留在目标里保持任意，于是 IH 是「对**所有** xs 成立」，步例里才能 `apply IH` 用在 tail 上。这正是第 12 章坑 2 的正面示范：**要归纳的变量先动，其余维度后收**。

### 17.5 什么时候用 option

| 场景 | 用法 |
|---|---|
| 查找类（head/nth/lookup） | 返回 option，失败显式 |
| 可能失败的计算（除法、解析） | option + bind 串联 |
| 调用方有合理默认值 | 在**调用处** `default`，不要在 API 里吞错 |
| 失败需要携带原因 | 变体类型 `Inductive result := Ok : A -> result \| Err : string -> result`（第 24 章用到类似手法） |

原则一句话：**让失败在类型里可见，在最近的地方处理**。

### 17.6 本章坑位清单（实测）

1. **`default` 放错层**：在库函数内部 default 会把「调用方该知道的失败」吞掉——兜底永远放在使用现场；
2. **忘记 bind 的短路语义**：链条里任何 None 都让整体 None——调试时从最前端的 None 查起；
3. **对 option 归纳**：option 无递归结构，`induction o` 没有意义（构造子的参数不是 option）——destruct 就够；
4. **`nth_option` 证明里 intros 顺序**：先 `intros xs` 再 `induction n` 会把 IH 锁死在具体 xs 上（第 12 章坑 2 的变体，17.4 有完整对照）。

---

## 第 18 章 策略武器库与模块

对应示例：`examples/18_tactics_modules.v`

### 18.1 自动化第一档：auto

前 17 章的证明全靠手工。`auto` 是自动化的入口——一个带提示库的深度优先搜索：

```coq
Theorem auto_ex : forall P Q : Prop, P -> (P -> Q) -> Q.
Proof. auto. Qed.
```

`auto` 能拼出：上下文假设的组合、`reflexivity` 可关闭的等式、简单构造子应用（split/left/…）。它**不能**做归纳、不能重写库里你没用 `Hint` 注册的定理。使用心法：

- 目标「一眼显然」（假设的直接组合、定义展开即相等）→ 先 `auto` 试试；
- `auto` 失败不损失什么——马上回到手工；
- 想给 auto 加弹药：`Hint Resolve 定理名.` 把定理挂进提示库（本教程不展开，知道有这回事即可）。

更激进的 `eauto`（会自己造存在证人）、`firstorder`（一阶逻辑专用）是后续的自学方向——先把手工程序练熟，才知道自动化在替你做什么。

### 18.2 assert：证明的分段

证明超过半屏就该拆。`assert (H : 陈述)` 造一个「局部引理」：花括号里现场证明它，之后 H 当普通假设用：

```coq
Theorem plus_rearrange : forall n m p q : nat,
  (n + m) + (p + q) = (m + n) + (p + q).
Proof.
  intros n m p q.
  assert (H : n + m = m + n).
  { apply Nat.add_comm. }
  (* 注意（实测坑）：老教材里的 plus_comm 在 8.20 已不存在，
     现名 Nat.add_comm——抄旧书先 Check 名字 *)
  rewrite H. reflexivity.
Qed.
```

assert 是**证明的模块化**：大定理拆成「引理链」，每段独立可读。与「提前把引理证成 Theorem」相比，assert 的引理是局部的——只在这个证明里可见，不污染命名空间。经验法则：会被多处复用的上升为 Theorem，单点使用的 assert 就地解决。

### 18.3 控制流组合：分号、try、嵌套

三个组合子让策略脚本紧凑：

```coq
(* ;  分号：让一条策略作用于当前全部目标 *)
Example semi_ex : forall b : bool, orb b true = true.
Proof.
  intros b. destruct b; reflexivity.
Qed.
```

`destruct b; reflexivity.` 读作「分情况后，每个情况各自 reflexivity」——两种情况一行收。展开写要两个子弹七行，等价但啰嗦。

```coq
(* try：失败就当无事发生 *)
intros n. simpl. try reflexivity.
```

`try reflexivity` 在证不了的目标上静默跳过——常与 `;` 连用：`destruct b; try reflexivity.` 留下证不动的情况继续手工。这两个组合子是「批量处理 + 例外管理」的策略语言版。

### 18.4 模块：命名空间

第 2 章示例就开始用 `Module ... End` 包装，现在正式讲。模块把一组定义（类型、函数、定理）打包进独立命名空间：

```coq
Module Stack.
  Definition t := list nat.
  Definition empty : t := [].
  Definition push (x : nat) (s : t) : t := x :: s.
  Definition pop (s : t) : option (nat * t) :=
    match s with
    | [] => None
    | h :: tl => Some (h, tl)
    end.
  Theorem pop_push : forall (x : nat) (s : t),
    pop (push x s) = Some (x, s).
  Proof. intros x s. reflexivity. Qed.
End Stack.

Compute (Stack.pop (Stack.push 5 Stack.empty)).   (* Some (5, []) *)
```

外部以 `Stack.pop` 点名访问；模块内互相直呼其名。定义与「关于定义的定理」同居一室——**接口和它的正确性证明在同一个命名空间里交付**，这是 Coq 工程化与普通语言最不同的气质。

### 18.5 模块签名：接口与封装

`Module Type` 声明**签名**（signature）——一组名字与类型的规定，`Parameter` 表示「签名不关心你怎么实现」，`Axiom` 表示「实现必须交付这条正确性证明」：

```coq
Module Type STACK_SIG.
  Parameter t : Type.                    (* 只说「有个类型」 *)
  Parameter empty : t.
  Parameter push : nat -> t -> t.
  Parameter pop : t -> option (nat * t).
  Axiom pop_push : forall (x : nat) (s : t),
    pop (push x s) = Some (x, s).        (* 行为承诺 *)
End STACK_SIG.

Module SealedStack : STACK_SIG := Stack.
```

`Module SealedStack : STACK_SIG := Stack.` 用签名**封印**了实现。效果（实测）：

```coq
Print SealedStack.t.
(* SealedStack.t : Type —— 看不到 list nat 了 *)

Fail Check (SealedStack.push 5 [1; 2]).
(* 签名外不知道 t = list nat，裸列表偷渡不进来 *)
```

表示细节被彻底隐藏，外部只能走接口——这就是**抽象数据类型（ADT）**，而且是带正确性证明的：接口上的 `Axiom pop_push` 由 `Stack` 内的 `Theorem pop_push` 实现满足（封印时 Coq 检查过签名匹配）。换实现（比如改用函数表示的队列）只要仍满足签名，所有使用方无感——**签名是模块间的类型系统**。

### 18.6 本章坑位清单（实测）

1. **`plus_comm` 已不存在**：8.20 移除了旧别名，现名 `Nat.add_comm`；老教材（包括 Software Foundations 旧版）抄代码先 Check；
2. **`contradiction` 不认 `0 = 1`**：报 `No such contradiction`——它只找「上下文里的 False / 构造子直接冲突」，数字不同要 `discriminate`（实测）；
3. **auto 空转**：对需要归纳的目标 auto 无能为力（它不会 induction）——显然要归纳就别等 auto；
4. **`;` 把错误信息搞乱**：`destruct b; try rewrite H; try reflexivity.` 一长串组合，哪步失败难定位——调试时展开成分步，绿了再合并；
5. **封印后的模块看不到表示**：`SealedStack.t` 只是抽象 Type，想对实现做计算/证明得用未封印的原模块——封装与便利的取舍。

---

## 第 19 章 表达式求值器：AST 入门

对应示例：`examples/19_ast.v`

### 19.1 用归纳类型定义一门小语言

本章把前 18 章的全部工具组装成一件真正的作品：一个算术表达式的**求值器**，配上一个**优化器**，再证优化器**不改变程序含义**。先定义语法——一个归纳类型，每个构造子是一种语法形态：

```coq
Inductive aexp : Type :=
  | AConst (n : nat)          (* 字面量 *)
  | AVar (x : string)         (* 变量 *)
  | APlus (a1 a2 : aexp)      (* a1 + a2 *)
  | AMinus (a1 a2 : aexp)     (* a1 - a2 *)
  | AMult (a1 a2 : aexp).     (* a1 * a2 *)
```

表达式 `2 + x * 3` 在 Coq 里就是这个**语法树**（AST，abstract syntax tree）：

```coq
APlus (AConst 2) (AMult (AVar "x") (AConst 3))
```

几个值得停下来体会的点：

- **语法即数据**：别的语言里「表达式」是编译器内部的黑盒，在 Coq 里它是个再普通不过的归纳类型——能 `Check`、能 `Compute`、能 match、能对它归纳证明；
- **没有语法糖**：AST 是抽象语法，括号、优先级这些具体写法的烦恼不存在（代价是手写 AST 略啰嗦，真做语言要配解析器——超出本书范围）；
- **构造子带参数标注**：`APlus (a1 a2 : aexp)` 是第 9 章 `node (l a r)` 的同款写法（参数直接写在构造子里），比老式「冒号在后面」紧凑。

### 19.2 状态与求值器

变量需要环境。最直接的表达：**状态 = 从变量名到值的函数**：

```coq
Definition state := string -> nat.
```

「函数当数据用」又一次出现——一个具体的状态就是一个具体的查表函数：

```coq
Definition st1 : state := fun x =>
  if String.eqb x "x" then 5 else 0.
```

求值器是对 AST 的结构递归——每种语法形态一个分支：

```coq
Fixpoint aeval (a : aexp) (st : state) : nat :=
  match a with
  | AConst n => n
  | AVar x => st x
  | APlus a1 a2 => aeval a1 st + aeval a2 st
  | AMinus a1 a2 => aeval a1 st - aeval a2 st
  | AMult a1 a2 => aeval a1 st * aeval a2 st
  end.

Example eval_ex1 : aeval (APlus (AVar "x") (AConst 1)) st1 = 6.
Proof. reflexivity. Qed.
```

`Fixpoint` 的终止性检查照常通过（递归都在子表达式上）。注意减法用的是 nat 的截断减（第 5 章的坑在这门小语言里复现——`x - y` 当 y > x 时得 0；做练习时留意）。

### 19.3 优化器：smart constructor 的设计

目标优化：`0 + e` 化简为 `e`。直接写会掉进一个坑——把判断塞进 `optimize` 的 APlus 分支：

```coq
(* 反面教材（伪码）：
Fixpoint optimize (a : aexp) :=
  match a with
  ...
  | APlus (AConst 0) e2 => optimize e2      (* 嵌套模式 *)
  | APlus e1 e2 => APlus (optimize e1) (optimize e2)
  ...
```

问题在证明：对 `a1` 归纳到 APlus 分支时，`optimize (APlus a1 a2)` 里 a1 是变量，嵌套模式 `AConst 0` 的 match 卡住化简不了，得再对 a1 穷举五种构造子——证明变成二十多行的模式体操。

工程解法是把「加法的构建」独立成 **smart constructor**：

```coq
Definition optimize_plus (e1 e2 : aexp) : aexp :=
  match e1 with
  | AConst 0 => e2
  | _ => APlus e1 e2
  end.

Fixpoint optimize (a : aexp) : aexp :=
  match a with
  | AConst n => AConst n
  | AVar x => AVar x
  | APlus e1 e2 => optimize_plus (optimize e1) (optimize e2)
  | AMinus e1 e2 => AMinus (optimize e1) (optimize e2)
  | AMult e1 e2 => AMult (optimize e1) (optimize e2)
  end.
```

效果（实测）：

```coq
Compute (optimize (APlus (AConst 0) (AVar "y"))).
(* = AVar "y" —— 0 + y 被吃掉 *)

Compute (optimize (APlus (APlus (AConst 0) (AVar "x")) (AConst 0))).
(* = APlus (AVar "x") (AConst 0)
   里层的 0 + x 被吃；x + 0 保留——优化器只认 0 在左，
   「e + 0 → e」的折叠留给第 24 章实战 *)
```

### 19.4 正确性证明：两步走

**定理**（优化器不改变语义）：

```coq
Theorem optimize_correct : forall (a : aexp) (st : state),
  aeval (optimize a) st = aeval a st.
```

分两步证。**第一步**，smart constructor 自己的正确性——注意它对**任意** u v 成立，与 optimize 无关，所以证明是独立的：

```coq
Lemma optimize_plus_correct : forall (u v : aexp) (st : state),
  aeval (optimize_plus u v) st = aeval u st + aeval v st.
Proof.
  intros u v st.
  unfold optimize_plus.        (* 展开定义，露出 match u *)
  destruct u; simpl; try reflexivity.
  destruct n; reflexivity.     (* AConst n 的 n 还要分 0 / S *)
Qed.
```

`unfold`（把定义展开成定义体）是新面孔但不必紧张：它就是「把名字换成定义」的 rewrite。`destruct u` 五种构造子里四种直接 reflexivity（两边形状相同），唯独 `AConst n` 里 n 未知，再分 `0` / `S k` 两步收掉。

**第二步**，主定理对 a 归纳，APlus 分支引用小引理：

```coq
Theorem optimize_correct : forall (a : aexp) (st : state),
  aeval (optimize a) st = aeval a st.
Proof.
  intros a st. induction a; simpl.
  - reflexivity.
  - reflexivity.
  - rewrite optimize_plus_correct. rewrite IHa1, IHa2. reflexivity.
  - rewrite IHa1, IHa2. reflexivity.
  - rewrite IHa1, IHa2. reflexivity.
Qed.
```

读 APlus 分支：目标左边是 `aeval (optimize_plus (optimize a1) (optimize a2)) st`——`optimize_plus_correct` 把这一层剥成 `aeval (optimize a1) st + aeval (optimize a2) st`，两个归纳假设再各自把 `optimize` 剥掉，两边归一。**五个分支、三个 rewrite，一个「优化器正确」的定理到手。**

这个 40 行的闭环值得敬畏：它就是 CompCert（验证编译器）、Verified SCC（验证垃圾回收）这类工业成果的**最小完整样本**——定义语言、写变换、证保持语义。规模差万倍，结构完全同构。

### 19.5 设计即证明友好

回头看，本章最大的心得不在证明里，而在**设计**里：把嵌套模式拆成 smart constructor，让「何时优化」的判断集中在一个小函数，主函数保持纯结构递归——于是主定理保持「标准归纳剧本」，特殊情况的复杂度被隔离进一个独立小引理。**为可证性而设计**（design for verifiability）是 Coq 工程师的核心技能：当你发现证明难得离谱，多半是定义可以改得更「结构化」。

### 19.6 本章坑位清单（实测）

1. **嵌套模式直接进 Fixpoint 导致证明爆炸**：19.3 的反面教材——用 smart constructor 隔离判断；
2. **`AConst n` 分支忘分 n**：`optimize_plus` 的 match 对 n 卡住，`destruct n` 补刀才收；
3. **nat 截断减法混进语言语义**：`AMinus` 沿用 nat 减法，负中间结果是 0——想语义正确可换 `Z` 结果类型或加 precondition（进阶）；
4. **String.eqb 的状态函数**：`st1` 用 `String.eqb x "x"` 判断——别用 `=`（那是 Prop，if 需要 bool，第 4 章的老朋友）；
5. **`rewrite IHa1, IHa2` 逗号**：`rewrite A, B` 是 `rewrite A. rewrite B.` 的缩写——顺序执行，B 失败整个失败，分开排查更容易。

---

## 第 20 章 列表定律证明实战

对应示例：`examples/20_list_laws.v`

### 20.1 本章任务

列表是函数式编程的「数组」，它的定律就是日常重构的理论基础。六条（示例 20 全部证毕）：

| # | 定律 | 日常意义 |
|---|---|---|
| 1 | `xs ++ [] = xs`（右单位元） | 拼空表不变 |
| 2 | `xs ++ ys ++ zs = (xs ++ ys) ++ zs`（结合律） | 括号随便挪 |
| 3 | `length (xs ++ ys) = length xs + length ys` | 长度可加 |
| 4 | `map g (map f xs) = map (fun x => g (f x)) xs`（融合律） | 两遍合一遍 |
| 5 | `rev (xs ++ ys) = rev ys ++ rev xs` | 反转分配且换序 |
| 6 | `rev (rev xs) = xs`（对合） | 翻两次还原 |

通用剧本（第 16 章已总结）：`induction xs as [| x tl IH]` → 基例 `reflexivity` → 步例 `simpl. rewrite IH. reflexivity.`。六条里四条是这个剧本的填空，两条有新戏——正好讲两个新课题。

### 20.2 课题一：定律互相引用（1、5、6）

**定律 1（右单位元）**是第 12 章 `my_app_nil_r` 的标准库版（用 `++` 记号）。留意与「左单位元」的对比：`[] ++ ys = ys` 是 `reflexivity` 一行（`++` 在左参数上递归，左边是 `[]` 直接化简），右边版本却要完整归纳——**定义的形状决定证明的价格**（第 12.5 节的法则再次兑现）。

**定律 5（反转分配）**开始引用前面的定律：

```coq
Theorem rev_app_distr : forall (A : Type) (xs ys : list A),
  rev (xs ++ ys) = rev ys ++ rev xs.
Proof.
  intros A xs ys. induction xs as [| x tl IH].
  - simpl. rewrite app_nil_r. reflexivity.
  - simpl. rewrite IH. rewrite <- app_assoc. reflexivity.
Qed.
```

两个新情况：**基例**化简后是 `rev ys ++ [] = rev ys`——又是那个「动不了的右单位元」，把刚证的定律 1 当引理用（`rewrite app_nil_r`）；**步例**要把 `(rev ys ++ rev tl) ++ [x]` 与 `rev ys ++ (rev tl ++ [x])` 对齐——`rewrite <- app_assoc` 反向用结合律挪括号。**定理开始互相组装成网**：定律 1 服务定律 5，定律 5 服务定律 6：

```coq
Theorem rev_involutive : forall (A : Type) (xs : list A),
  rev (rev xs) = xs.
Proof.
  intros A xs. induction xs as [| x tl IH].
  - reflexivity.
  - simpl. rewrite rev_app_distr. rewrite IH. simpl. reflexivity.
Qed.
```

「翻两次等于不翻」——口头上一秒钟，机器面前需要定律 5 + 归纳 + 化简三件套。这就是证明工程的手感：**没有孤立的定理，只有定理网**。

### 20.3 课题二：归纳假设不够用怎么办

一个值得亲手的失败（推荐在 CoqIDE 里试）：证**累加器版反转**（第 10 章 `fast_rev`）与标准 `rev` 的一致性。naive 剧本直接上：

```coq
(* 想证：rev_acc [] xs = rev xs *)
Proof.
  intros A xs. induction xs as [| x tl IH].
  - reflexivity.                  (* 两侧都空，过了 *)
  - simpl. rewrite IH.            (* 卡死！ *)
```

步例化简后是 `rev_acc (x :: []) tl = rev tl ++ [x]`——**累加器不再是 []**，而 IH 只谈 `rev_acc [] tl`，假设够不着。这正是第 15 章 two_step 的同款困境，同款解法——**一般化：把命题改成对任意累加器成立**（注意 intros 顺序的细节）：

```coq
Lemma rev_acc_correct : forall (A : Type) (xs acc : list A),
  rev_acc acc xs = rev xs ++ acc.
```

**加强后的命题反而好证**：IH 变成「对任意 acc」，步例的累加器 `x :: acc` 也是它的实例。而 `rev_acc [] xs = rev xs` 作为推论一击而得。这一招（**generalize the accumulator**）与第 15 章（strengthen with conjunction）是同一个思想的两件衣服：**归纳假设是白送的燃料，命题写得越「一般」，燃料越足**。

### 20.4 一个证明细节的工具箱

本章六条定律的证明里，三个高频动作值得点名：

1. **借定律**：基例/步例化简出的「标准形状」（`xs ++ []`、括号位置）直接 rewrite 前面证好的定律，别再手证一遍；
2. **调方向**：`rewrite <- app_assoc` 挪括号——先想清楚要消的模式在哪侧（第 13.1 节的方向学）；
3. **看形状选归纳变量**：定律 3、4 对 xs 归纳剧本即过；涉及两个列表的定律（如 `length (xs ++ ys) = ...`）也只对第一个归纳——因为 `++` 在它上面递归。

### 20.5 rev_acc_correct 完整证明（实测）

失败与成功的差别只在**一个 intros 的顺序**（失败版的报错与本节脚本都经过实测）：

```coq
Lemma rev_acc_correct : forall (A : Type) (xs acc : list A),
  rev_acc acc xs = rev xs ++ acc.
Proof.
  intros A xs.            (* 关键：只收 A 和 xs —— acc 留在目标里！
                             若先 intros acc 再 induction，IH 就被
                             锁死在固定 acc 上，步例 rewrite IH 直接
                             报 Found no subterm matching *)
  induction xs as [| x tl IH]; intros acc.
  - reflexivity.
  - simpl. rewrite IH. rewrite <- app_assoc. simpl. reflexivity.
Qed.
```

步例目标：`rev_acc (x :: acc) tl = (rev tl ++ [x]) ++ acc`。`rewrite IH`（IH : **forall acc**, rev_acc acc tl = rev tl ++ acc）把左边换成 `rev tl ++ x :: acc`；`rewrite <- app_assoc` 把右边括号外挪变成 `rev tl ++ [x] ++ acc`；`simpl` 把 `[x] ++ acc` 化成 `x :: acc`，两边相同。推论随之而来：

```coq
Theorem fast_rev_correct : forall (A : Type) (xs : list A),
  rev_acc [] xs = rev xs.
Proof.
  intros A xs. rewrite rev_acc_correct. rewrite app_nil_r. reflexivity.
Qed.
```

**没有那步「一般化」，这一切无从谈起**——本教程第二次、也是最后一次强调这个心法。

### 20.6 本章坑位清单（实测）

1. **累加器命题没一般化**：`rev_acc [] xs` 直接归纳 IH 够不着，改成 `forall acc, rev_acc acc xs = rev xs ++ acc`（20.3 的完整案例）；
2. **`rev (x :: tl) ++ acc` 化简时机**：stdlib `rev` 定义为 `rev (x::l) = rev l ++ [x]`，simpl 展开后形状才可见——步例先 simpl 再 rewrite 的顺序不能乱；
3. **rewrite 定律时同名混淆**：自己证的 `app_nil_r` 与 stdlib 的 `List.app_nil_r` 同名——自己的在后会遮蔽库版（本教程自证的版本足够用，两版陈述一致，实测无冲突）；
4. **想对 ys 归纳**：定律 3 对 `ys` 归纳会把化简引向 `length xs` 的死胡同——归纳变量跟着**递归定义的参数**走（`++` 递归在第一个参数）。

---

## 第 21 章 插入排序与正确性证明

对应示例：`examples/21_sorting.v`

### 21.1 目标：不只会写，还要证对

前 20 章的定理都是「数学性质」。本章证一个**算法正确**——插入排序。先把「排序正确」说清楚，它必须是两件事的合取：

1. **有序**：输出列表从头到尾不减；
2. **是重排**：输出的元素恰好是输入的元素（不多不少不重复消失）。

只满足第一条的垃圾函数有的是（`fun _ => []` 有序但丢了所有元素），只满足第二条的也不少（`id` 保持元素但可能无序）。**正确 = 两条都要**——把「正确」拆成可判定的子性质，本身就是形式化的第一课。

### 21.2 算法

```coq
Fixpoint insert (x : nat) (l : list nat) : list nat :=
  match l with
  | [] => [x]
  | y :: ys => if Nat.leb x y then x :: y :: ys else y :: insert x ys
  end.

Fixpoint sort (l : list nat) : list nat :=
  match l with
  | [] => []
  | x :: xs => insert x (sort xs)
  end.

Compute (sort [3; 1; 4; 1; 5; 9; 2; 6]).   (* = [1;1;2;3;4;5;6;9] *)
```

`insert` 把 x 插进**已经有序**的列表（`Nat.leb x y` 用了第 16 章的 destruct eqn 老朋友），`sort` 经典的「排序尾部 + 插入头部」。两个 Fixpoint 都通过终止检查（递归在 `ys`/`xs` 上）。能跑，但「跑了几组样例都对」与「正确」之间的鸿沟，正是本章要填的。

### 21.3 自造「有序」谓词

标准库有 `Sorted`，但为了看清机制，我们**自己定义**有序——「每个元素 ≤ 它右边的全部元素」：

```coq
Fixpoint le_all (x : nat) (l : list nat) : Prop :=
  match l with
  | [] => True
  | y :: tl => x <= y /\ le_all x tl
  end.

Fixpoint sorted (l : list nat) : Prop :=
  match l with
  | [] => True
  | x :: tl => le_all x tl /\ sorted tl
  end.
```

两个 Fixpoint 住在 `Prop` 里——**定义命题与定义函数用同一门语言**（对比第 15 章的 `even`）。`le_all x l`（x 全场压制 l）是辅助命题，`sorted` 主谓词。这种「每个元素压住后面所有」的定义比「相邻两两有序」啰嗦一点，但证明时不用额外引理（相邻版本要另证「局部有序 ⇒ 全局有序」）。

### 21.4 正确性之一：插入保序

主定理 `insert_sorted : sorted l -> sorted (insert x l)` 需要两个小引理铺垫——它们是本章真正的教学内容（**先证工具引理**的工程习惯）：

```coq
(* 引理 1：<= 的传递性穿透 le_all *)
Lemma le_all_le : forall (x y : nat) (l : list nat),
  x <= y -> le_all y l -> le_all x l.
Proof.
  intros x y l Hxy H. induction l as [| z zs IH].
  - simpl. exact I.
  - simpl in *. destruct H as [Hyz Hrest]. split.
    + apply (Nat.le_trans x y z Hxy Hyz).
    + apply IH. exact Hrest.
Qed.

(* 引理 2：更大的元素插进来，不破坏 y 的全场压制 *)
Lemma le_all_insert_lt : forall (x y : nat) (l : list nat),
  y < x -> le_all y l -> le_all y (insert x l).
```

（两条引理的完整脚本见示例 21。）引理 2 值得盯着看：`insert x l` 的**头**要么是 x（x 更小先落座）要么是 l 的头——两种情况 y 都压得住，这就是它需要按 `Nat.leb x z` 与列表形状分情况的原因。有了两把工具，主定理是干净的三段式：

```coq
Theorem insert_sorted : forall (x : nat) (l : list nat),
  sorted l -> sorted (insert x l).
Proof.
  intros x l H. induction l as [| y ys IH].
  - simpl in *. simpl. split. exact I. exact I.
  - simpl in *. destruct H as [Hle Hsorted]. simpl.
    destruct (Nat.leb x y) eqn:E.
    + apply Nat.leb_le in E. split.
      * split. exact E. apply le_all_le with y. exact E. exact Hle.
      * split. exact Hle. exact Hsorted.
    + apply Nat.leb_gt in E. split.
      * apply le_all_insert_lt. exact E. exact Hle.
      * apply IH. exact Hsorted.
Qed.
```

值得点名的三个动作：**`apply 引理 with 中转参数`**（`le_all_le with y` 显式指定中间变量，避免推断歧义）；**`Nat.leb_le` / `Nat.leb_gt`**（把 bool 的比较结果翻译成 Prop 世界的事实——第 15 章两座桥的实战应用）；**`destruct (Nat.leb x y) eqn:E`**（第 16 章的 filter 老朋友，第三次出场）。

### 21.5 正确性之二：插入是重排

「重排」用标准库的 `Permutation`（来自 `Sorting.Permutation`）——它自带装配零件：

```coq
Theorem insert_perm : forall (x : nat) (l : list nat),
  Permutation (x :: l) (insert x l).
Proof.
  intros x l. induction l as [| y ys IH].
  - simpl. apply Permutation_refl.
  - simpl. destruct (Nat.leb x y) eqn:E.
    + apply Permutation_refl.
    + apply Permutation_trans with (y :: x :: ys).
      * apply perm_swap.        (* x::y::ys ~ y::x::ys *)
      * apply perm_skip. exact IH.   (* 头保持，尾部 ~ *)
Qed.
```

`perm_skip`（头不动尾换）、`perm_swap`（相邻交换）、`Permutation_trans`（传递拼装）是重排世界的乐高。`apply ... with (y :: x :: ys)` 又一次指定中转站——`Permutation_trans with` 的用法与 `le_all_le with` 同款。

### 21.6 合成：sort 的双重正确性

两条腿都备好，`sort` 的正确性几乎是免费的：

```coq
Theorem sort_sorted : forall l : list nat, sorted (sort l).
Proof.
  induction l as [| x xs IH].
  - simpl. exact I.
  - simpl. apply insert_sorted. exact IH.
Qed.

Theorem sort_perm : forall l : list nat, Permutation l (sort l).
Proof.
  induction l as [| x xs IH].
  - apply Permutation_refl.
  - simpl. apply Permutation_trans with (x :: sort xs).
    + apply perm_skip. exact IH.
    + apply insert_perm.
Qed.

Theorem sort_correct : forall l : list nat,
  sorted (sort l) /\ Permutation l (sort l).
Proof.
  intros l. split.
  - apply sort_sorted.
  - apply sort_perm.
Qed.
```

`sort_correct` 盖章：**对任意长度的任意 nat 列表，插入排序产出有序的输入重排**。这就是「验证算法」的全过程——比你见过的任何测试套件都强，且只有约 80 行。复杂算法（归并、快排）的证明结构完全相同，只是引理更厚——那是「工作量」的差异，不是「方法论」的差异。

### 21.7 本章坑位清单（实测）

1. **`apply ... with` 漏参数**：`apply le_all_le.` 会被中间变量 y 卡住（无法唯一确定）——`with y` 显式给；
2. **bool 比较直接当命题用**：`x <=? y` 是 bool，`if` 里能用；证明时要先 `apply Nat.leb_le in E` 过桥（第 15 章的 reflect 思想落地）；
3. **`Permutation` 的零件名**：`perm_skip`/`perm_swap` 小写开头（不是 `Permutation_skip`）——`Search Permutation` 现查；
4. **自定义谓词忘了 `simpl`**：`sorted (x :: ys)` 是 Fixpoint 应用，split 前通常已被 simpl 展开；卡住时先 `simpl in *`；
5. **想对 `sort l` 归纳证明有序**：归纳发生在**输入列表 l** 上，`sort` 的展开交给 simpl——归纳对象永远是「数据的结构」，不是「函数的结果」。

---

## 第 22 章 数值专题：nat、N 与 Z

对应示例：`examples/22_numbers.v`

### 22.1 nat 的成本模型：数学家的数 vs 工程师的数

全书用 nat 是**为了证明**——形状只有 O 和 S，归纳原理简单。但第 4 章那个实测坑（`Compute (Nat.pow 2 100)` 内存耗尽）背后是一元表示的成本模型：

| | nat | N / Z |
|---|---|---|
| 表示 | 一元（S 链） | 二进制（positive） |
| 3 是什么 | `S (S (S O))` | `11%positive` 两位 |
| 2^64 需要 | 1.8×10¹⁹ 个构造子 | 64 位 |
| 加法 | O(n) 步逐层 S | O(log n) 位运算 |
| 与证明的关系 | 归纳原理直接、全书主战场 | 引理丰富但定义复杂 |

实测对比（示例 22）：`Nat.pow 2 16`（65536 个 S）还能瞬间算完并打印；`Z.pow 2 64`、`Z.pow 2 100` 输出完整十进制也是瞬间。

```coq
Print Z.
(* Inductive Z : Set :=
     Z0 : Z | Zpos : positive -> Z | Zneg : positive -> Z *)
```

`positive` 是一颗二进制树；`Z0`/`Zpos`/`Zneg` 三构造子——还记得第 5 章 `if 1%Z` 被拒绝吗？就是因为 Z 有**三个**构造子，不满足 if 的「恰好两个」要求，伏笔在此闭环。

### 22.2 选型决策表

| 需求 | 用什么 |
|---|---|
| 写定义、做归纳证明 | **nat**（形状简单，全书默认） |
| 有符号算术、大数计算 | **Z** |
| 明确无符号的二进制 | **N** |
| 程序逻辑里做分支 | bool（`=?` `<=?`）+ reflect 桥 |
| 性能关键的已验证代码 | Coq 里证明，Extraction 抽取成 OCaml 后跑（第 24 章） |

互通的桥：`Z.of_nat` / `Z.to_nat` / `N.of_nat` / `N.to_nat`。注意转换本身有成本（一元 ↔ 二进制是表示形状的整体改写），**在边界一次转换、内部统一数系**是工程习惯。

### 22.3 lia：算术证明的自动化

前 21 章证过 `n + 0 = n`、`plus_comm`——纯算术的体力活。标准库的 `lia`（linear integer arithmetic，来自 `Lia`）把这类活自动包了：

```coq
From Coq Require Import ZArith Lia.

Theorem nat_lia : forall n m : nat, n <= m -> n + 0 <= m.
Proof.
  intros n m H. lia.
Qed.

Theorem z_lia : forall a b : Z, (a <= b)%Z -> (a - b <= 0)%Z.
Proof.
  intros a b H. lia.
Qed.
```

`lia` 处理**线性**目标：加减、常数、比较的任意组合（nat 与 Z 都吃）。非线性的（含未知数相乘，如 `n * n >= 0`）它管不了——那种回到手证或 `nia`（更慢的非线性版）。使用心法：**归纳结构是本质的目标手证，纯算术变形的尾声交 lia**。注意 Z 上的比较要 `%Z` 作用域——裸写 `(a <= b)` 会被解析成 nat 的 `<=`，报「expected nat got Z」（实测，又一条作用域坑）。

### 22.4 本章坑位清单（实测）

1. **`Compute` 大 nat 指数**：`Nat.pow 2 100` 直接 OOM——大数用 `Z.pow`；「装得下」与「算得动」是两回事（第 4 章老坑的算术版）；
2. **Z 上的运算符裸写**：`(a <= b)%Z` 才是 Z 的比较，裸写按 nat 解析报类型错——`Open Scope Z_scope`（模块内）或 `%Z`（局部）二选一；
3. **`lia` 不认非线性**：目标里出现未知数相乘就放弃——先手证非线性骨架，线性收尾再喂给它；
4. **`Z.to_nat` 的隐藏成本**：2^16 瞬间变回 65536 个 S——转换是表示重写，大数转换本身可能爆炸。

---

## 第 23 章 测试与断言风格

对应示例：`examples/23_testing.v`

### 23.1 Example 即测试

Coq 里不需要测试框架——`Example` + `reflexivity` 就是断言，`coqc` 就是测试运行器：

```coq
Definition inc (n : nat) : nat := S n.

Example test_inc_1 : inc 0 = 1.
Proof. reflexivity. Qed.

Example test_inc_41 : inc 41 = 42.
Proof. reflexivity. Qed.
```

改坏 `inc` 的任何一行，`build.ps1 -All` 当场全红。回归测试的全部要素（断言、运行、失败定位）都在，只是「跑测试」变成了「编译检查」。本教程每个示例文件从第 1 章起就在用这套——你已经在 TDD 了。

### 23.2 负向断言

「不该发生的」也要钉住：

```coq
Example test_inc_neg : inc 0 <> 2.
Proof. discriminate. Qed.

Fail Check (inc true).     (* 类型误用，如期失败 *)
```

`<>`（不等于）配 `discriminate`（第 13 章）锁具体值；`Fail`（第 3 章）锁「这行不该编译过」。两类负向断言把 API 的边界写成可执行文档。

### 23.3 从测试升级为定理

测试思维与证明思维的分界线是 **forall**。工作流（示例 23 的完整示范）：

```coq
(* 第一步：具体样例找感觉 *)
Example test_all_even_1 : all_even [2; 4; 6] = true.
Proof. reflexivity. Qed.

(* 第二步：把想要的性质一般化 *)
Theorem all_even_app : forall l1 l2 : list nat,
  all_even l1 = true -> all_even l2 = true
  -> all_even (l1 ++ l2) = true.
Proof.
  intros l1. induction l1 as [| x tl IH]; intros l2 H1 H2.
  - exact H2.
  - simpl in H1.
    apply andb_true_iff in H1.   (* && = true 拆两个 = true *)
    destruct H1 as [Ex Et].
    simpl. rewrite Ex. simpl.
    apply IH; assumption.
Qed.
```

具体值是测试（跑有限个），量化命题是证明（覆盖无穷个），Example 是通往 Theorem 的脚手架。`apply IH; assumption.` 的分号用法（第 18 章）在这里顺手续掉两个前提。`andb_true_iff` 是 bool 世界的拆桥工具——第 14 章 `destruct` 拆 `/\` 的 bool 版。

### 23.4 公理审查：Print Assumptions

测试证明「行为对」，`Print Assumptions` 审查「出身清白」（第 3 章埋的线）：

```coq
Theorem honest : 2 + 2 = 4.
Proof. reflexivity. Qed.
Print Assumptions honest.
(* Closed under the global context —— 干净 *)

Axiom bogus : forall n : nat, n = 0.
Theorem poisoned : 3 = 0.
Proof. apply bogus. Qed.
Print Assumptions poisoned.
(* Axioms:
   bogus : forall n : nat, n = 0 —— 出身有问题！ *)
```

一条 `Admitted`、一个手滑的 `Axiom`，都会在这里现形（实测输出如上）。**工程化纪律**：CI 里对每个公开定理跑 `Print Assumptions`，只许 `Closed under the global context`——「无公理依赖」是可验证代码的最低出厂标准。

### 23.5 什么时候测试、什么时候证明

| 场景 | 手段 |
|---|---|
| 具体行为快照（回归锚点） | Example + reflexivity |
| API 误用应被拒绝 | Fail Check / Fail Definition |
| 不变式对一切输入成立 | Theorem + induction |
| 纯算术性质 | lia（第 22 章） |
| 发布检查 | Print Assumptions 全绿 |

成本直觉：Example 十秒写完零维护；Theorem 十分钟起步但永久免疫。**原型期堆 Example，接口稳定后把关键性质升格为 Theorem**——两层的配比就是工程判断。

### 23.6 本章坑位清单（实测）

1. **`Fail Example 名 : 假命题. Proof. reflexivity. Qed.`**：Fail 只包一句——陈述句本身合法（成功），下一个 reflexivity 才失败且不在 Fail 保护内，文件直接编译失败。负向断言的正确写法是 `Example 名 : x <> y. Proof. discriminate. Qed.`（实测对照）；
2. **`<>` 目标忘了它是否定**：`x <> y` 即 `x = y -> False`——`discriminate`/`intros H` 后引爆即可，别试图「直接证」；
3. **Print Assumptions 输出 Axioms 却继续提交**：审查输出要进 CI，人工看一眼的日子久了会疲劳；
4. **测试 bool 函数忘了负例**：只测 `= true` 的样例测不出「永远返回 true」的假实现——`all_even [2;3] = false` 这类负例与正例同等重要。

---

## 第 24 章 综合实战：表达式解释器与优化器

对应示例：`examples/24_project.v`

### 24.1 项目目标

收官项目把全书的工具连成一条完整的生产线：

1. **定义语言**：带变量的算术表达式（第 19 章的 aexp）；
2. **解释器**：状态下的求值（结构递归）；
3. **两个优化 pass**：吃掉 `0 + e`、常量折叠；
4. **组合证明**：流水线整体保语义——两个 pass 的正确性**免费合成**；
5. **抽取**：验证过的优化器导出成 OCaml，在真实世界运行。

这条线就是「验证编译器」的微缩景观：CompCert 的每个优化 pass 都配一条「语义保持」定理，pass 之间的组合因为各自正确而自动正确。你要写的全部代码不到 150 行。

### 24.2 语言与解释器

与第 19 章相同，直接复用：

```coq
Inductive aexp : Type :=
  | AConst (n : nat) | AVar (x : string)
  | APlus (a1 a2 : aexp) | AMinus (a1 a2 : aexp) | AMult (a1 a2 : aexp).

Definition state := string -> nat.

Fixpoint aeval (a : aexp) (st : state) : nat :=
  match a with
  | AConst n => n
  | AVar x => st x
  | APlus a1 a2 => aeval a1 st + aeval a2 st
  | AMinus a1 a2 => aeval a1 st - aeval a2 st
  | AMult a1 a2 => aeval a1 st * aeval a2 st
  end.

Example run1 : aeval (APlus (AVar "x") (AMult (AConst 2) (AConst 3)))
                    (fun _ => 10) = 16.
Proof. reflexivity. Qed.
```

### 24.3 pass 1：吃掉 0 + e

第 19 章的 `optimize0` 原样搬来（smart constructor 设计、正确性两步证法——忘了的话翻回去，这里是复用不是新知识）：

```coq
Theorem optimize0_correct : forall (a : aexp) (st : state),
  aeval (optimize0 a) st = aeval a st.
```

### 24.4 pass 2：常量折叠

新 pass：两个操作数都折成常量时，直接算掉：

```coq
Fixpoint const_fold (a : aexp) : aexp :=
  match a with
  | APlus e1 e2 =>
      match const_fold e1, const_fold e2 with
      | AConst n1, AConst n2 => AConst (n1 + n2)
      | e1', e2' => APlus e1' e2'
      end
  | AMinus e1 e2 =>
      match const_fold e1, const_fold e2 with
      | AConst n1, AConst n2 => AConst (n1 - n2)
      | e1', e2' => AMinus e1' e2'
      end
  | AMult e1 e2 =>
      match const_fold e1, const_fold e2 with
      | AConst n1, AConst n2 => AConst (n1 * n2)
      | e1', e2' => AMult e1' e2'
      end
  | AConst n => AConst n
  | AVar x => AVar x
  end.

Compute (const_fold (APlus (AConst 2) (AMult (AConst 3) (AConst 4)))).
(* = AConst 14 —— 整棵子树折成一个数 *)
```

双 scrutinee 的嵌套 match（第 7 章）在这里正合适。正确性证明有一个新看点——**rewrite 的方向反过来用 IH**：

```coq
Theorem const_fold_correct : forall (a : aexp) (st : state),
  aeval (const_fold a) st = aeval a st.
Proof.
  intros a st. induction a; simpl.
  - reflexivity.
  - reflexivity.
  - rewrite <- IHa1. rewrite <- IHa2.
    destruct (const_fold a1) eqn:E1; destruct (const_fold a2) eqn:E2;
      reflexivity.
  - (* AMinus：同款 *) ...
  - (* AMult：同款 *) ...
Qed.
```

APlus 分支的目标里，`const_fold a1` 藏在 match 的 scrutinee 位置——`rewrite IHa1`（正向）找不到 `aeval (const_fold a1) st` 这个模式；**先 `rewrite <- IHa1`** 把右边的 `aeval a1 st` 替换成 `aeval (const_fold a1) st`，两边就都谈 `const_fold` 的结果了。随后 `destruct (const_fold a1) eqn:E1; destruct (const_fold a2) eqn:E2` 十二种组合全部 `reflexivity`（分号把 reflexivity 批量发给每个目标）。「IH 用反向」是嵌套 match 场景的标准解法，与第 13 章的方向学完全自洽。

### 24.5 流水线：正确性免费合成

```coq
Definition pipeline (a : aexp) : aexp := const_fold (optimize0 a).

Theorem pipeline_correct : forall (a : aexp) (st : state),
  aeval (pipeline a) st = aeval a st.
Proof.
  intros a st.
  unfold pipeline.
  rewrite const_fold_correct.
  rewrite optimize0_correct.
  reflexivity.
Qed.
```

读一遍：`unfold` 展开 pipeline 定义（第 19 章的 unfold），两个 pass 的正确性定理接力 rewrite，三行收工。**这就是组合的正确性**——每个环节单独验证，串联后的保证自动成立，不需要对整条流水线重新归纳。CompCert 由几十个 pass 组成而依然可维护，靠的正是这个性质。

```coq
Example pipeline_demo :
  pipeline (APlus (AConst 0) (AMult (AConst 3) (AConst 4))) = AConst 12.
Proof. reflexivity. Qed.
```

`0` 被吃、常量被折，一次到位——且 `pipeline_correct` 担保**任何**表达式经过流水线语义不变。

### 24.6 抽取：从证明世界到运行世界

最后一步，把验证过的优化器变成可执行代码：

```coq
From Coq Require Import Extraction.

Recursive Extraction pipeline.
```

`Recursive Extraction` 把 pipeline（及其依赖的 aeval、aexp……）翻译成 OCaml 源码打印出来——类型、函数、递归全部直译（nat 仍是 `O | S of nat`，要高效可在 Z 上重做计算核心或让抽取走 `Extract Inductive nat => int` 一类的映射，超出本书范围）。工作流闭环：

```text
Coq：定义 + 定理                    OCaml：编译运行
     |        \                        ^
     |         \—— Recursive Extraction ——+
     +—— 证明正确性（留在 Coq，不需要运行时携带）
```

证明是开发期的脚手架，运行期零开销——**「经过验证的程序」不需要随身带着证明**。这个模型叫「验证后抽取」，是 Coq 走向工业界的主干道（CompCert 的 C 编译器本体、Fiat Crypto 的密码算法，都以这种方式交付）。

> 坑（实测）：`Recursive Extraction` 裸写报 `illegal begin of vernac`——必须先 `From Coq Require Import Extraction.`。

### 24.7 本章坑位清单（实测）

1. **`Recursive Extraction` 需要 Require**：先 `From Coq Require Import Extraction`，否则报非法命令（24.6 的坑）；
2. **const_fold 证明里 IH 用正向**：`rewrite IHa1` 在嵌套 match 场景找不到模式——`rewrite <- IHa1` 先把两边对齐（24.4 的完整分析）；
3. **流水线证明忘了 unfold**：`pipeline a` 不展开，rewrite 的模式藏在定义后面够不着；
4. **抽取产物里 nat 仍是一元**：性能敏感的抽取目标要规划数系（Z 核心 + 映射），别默认抽取完就是快的；
5. **想给语言加 if/while**：语法加个构造子容易，求值器加分支也容易——但 while 需要**终止性度量**或改用燃料（第 10 章 10.4），这是 Software Foundations《PLF》卷的入口，本书到此为止。

---

## 第 25 章 坑清单与最佳实践

### 25.1 全书坑位总清单

二十五章攒下的坑，按「第一天就会踩」到「写项目才会踩」排序。每条都经过 8.20.1 实测，括号内是原始章节。

**入门第一周（环境与语法）：**

1. 句子忘句点 `.`，coqtop 一动不动「等你把话说完」（2）；
2. `8 / 2`、`5 mod 2`、`=?`、`<=?`、`<?`、`^` 都要 `Require Import Arith`；`&&` `||` 要 `Open Scope bool_scope`；`[1;2]` 要 `Import ListNotations`——记号按作用域懒加载，裸环境只有 `+ - *` 和 `andb/orb/negb`（2/5/8）；
3. `Fail` 的失败原因只在 coqtop/CoqIDE 显示，coqc 批处理静默（2/3）；
4. 证明中途忘 `Qed`/`Abort` 就开新定义，报错位置莫名其妙——`Show.` 确认状态（2/3）；
5. `Qed` 时才报 `Attempt to save an incomplete proof`——病因在前面，子弹用全（3/11）。

**类型与表达式：**

6. `3` 是 `S (S (S O))` 不是机器整数；`Compute (Nat.pow 2 100)` 直接 OOM——「装得下 ≠ 算得动」（4/22）；
7. `Compute (3 = 3)` 不报错，打印 `= 3 = 3 : Prop`——求值不回答命题真假（4）；
8. **if 接受任何两构造子类型**：`if 1 then 2 else 3` 合法且 = 3（O 走 then、S 走 else）——别信「条件必须 bool」的直觉（5）；
9. `1 - 2 = 0`（截断减法）、`5 / 0 = 0`（除零静默）——nat 算术两大暗坑（5）；
10. 一元负号 `- 1` 在 nat 上不存在；负数去 `%Z`，且 Z 的比较运算要 `%Z` 限定（5/22）；
11. `A * B`/`A + B` 与算术同形不同义——`Locate` 查作用域（4/5）；
12. 参数化 Record 的投影带显式类型参数（`first _ t1` 或 `Arguments first {A}`）；字段名全局唯一不能重名（6）。

**模式匹配与递归：**

13. 漏分支是错（`Non exhaustive`），冗余分支也是错（`Pattern ... is redundant`，8.20 是硬错误）（7）；
14. 没有 or 模式（`| A | B => ...` 写不了）；模式变量会遮蔽外层（7）；
15. 递归函数写成 `Definition`——报「引用未找到」，真因是名字没注册（9/10）；
16. 守卫检查会**展开定义**：`S k => f (k - 1)` 实测放行；但 `f (n - 1)`/`f n`（参数本身）被拒——分支里递归用模式变量（10）。

**证明：**

17. **rewrite 的方向学**：让要找的模式处在复合模式一侧；裸变量一侧正向 rewrite 行为不稳（实测两种怪象都遇过）（12/13）；
18. 同名定理方向可能相反（本书 plus_n_O 与标准库 plus_n_O 同姓不同向）——rewrite 前 `Check`（12）；
19. `plus_comm` 在 8.20 已移除，现名 `Nat.add_comm`；`Permutation` 零件是 `perm_skip`/`perm_swap` 小写——抄旧资料先 Check（18/21）；
20. `~` 是定义不是构造子，intro 解构模式进不去——拆到 `~P` 为止收下当函数用（14）；
21. 构造逻辑里证不出排中律与双否消去——需要经典逻辑就 `Classical`，并接受公理依赖（14）；
22. 两步递归的性质朴素归纳证不动——强化命题（`P n /\ P (S n)` 或一般化累加器）；**intros 顺序锁死 IH** 是最常见的翻车原因：要归纳的变量最后收（12/15/17/20）；
23. `destruct (p x)` 后 filter 的 `if` 会复活——`eqn:E` 记住结果、`rewrite E` 补刀（16/21）；
24. `contradiction` 不认 `0 = 1`（报 No such contradiction）——数字矛盾用 `discriminate`（18）；
25. `Fail Example 名 : 假命题.` 包不住整段证明——负向断言写 `x <> y` + `discriminate`（23）。

**工程化：**

26. `Admitted`/`Axiom` 混进正式代码——`Print Assumptions` 审查，只许 `Closed under the global context`（3/23）；
27. `Recursive Extraction` 要先 `Require Import Extraction`，裸写报非法命令（24）；
28. 封印模块（`Module M : SIG`）看不到表示——对实现做计算用未封印原模块（18）。

### 25.2 最佳实践十条

1. **先 Check 再 rewrite**：方向、类型、存在性，一秒钟避免十分钟困惑；
2. **子弹用全，prove 的每个目标都点名**：可读性就是正确性的一半；
3. **要归纳的变量最后 intros**，其余维度保持任意——IH 的强度就是证明的燃料；
4. **卡住先 Search**：描述想要的结论形状，让库回答；确无再手证；
5. **纯算术的尾巴交 lia**，归纳结构自己掌握——自动化的边界要心里有数；
6. **Smart constructor 隔离判断**：嵌套模式塞进 Fixpoint 会让证明爆炸（19 的正反面）；
7. **定义为可证性而设计**：证明难得离谱时，先怀疑定义不够结构化；
8. **Example 是脚手架，Theorem 是资产**：原型期堆前者，接口稳定后升格后者；
9. **模块+签名交付 ADT**，接口连同正确性定理一起封印（18 的 STACK_SIG）；
10. **每个 pass 一条正确性定理**，组合的正确性免费合成（24 的 pipeline）。

### 25.3 下一步去哪里

- **Software Foundations**（softwarefoundations.cis.upenn.edu）：逻辑（Logic）、程序语言（PLF）、验证（VF）三卷，本书第 19/24 章的直接源头，习题质量全领域第一；
- **Mathematical Components / MathComp**：另一套证明风格（SSReflect 小步战术），适合大量数学推理；
- **Rocq 9 的迁移**：`From Coq Require ...` → `From Stdlib Require ...`（或开兼容），趁早在新旧资料间建立翻译意识；
- **真项目**：给第 24 章的语言加布尔与 if（易）、加 let 绑定（易）、加函数调用（中）、加 while（难——燃料或度量）、写个解析器从字符串构造 aexp（与验证正交的纯工程）。

### 25.4 结语

25 章前你面对的是「证明助手」这个词；现在你手里有：一门能定义数据、写函数、组织模块的语言，一套把命题变成类型、把推理变成程序的世界观，和一条从 Example 到 Theorem、从函数到流水线、从证明到抽取的完整生产线。

最重要的练习只有一种：**打开 Coq，写下你想证的东西，然后动手**。它会顶嘴，会拒绝，会把你的每个「显然」逼成原理——这正是它四十年来存在的意义。

---

（全书完 · 25 章 · 示例 24 个 · 全部经 coqc 8.20.1 编译验证）









