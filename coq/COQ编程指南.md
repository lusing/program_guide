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

<!-- BATCH1-CONTINUES -->



