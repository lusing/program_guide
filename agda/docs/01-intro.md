# 01 · 认识 Agda

在写下第一行 Agda 之前，先把「Agda 到底是什么」说清楚：它既是一门**依赖类型
证明助手**——你在里面陈述定理、程序就是证明，类型检查通过即定理成立；同时又是
一门**total（全部有定义）的函数式语言**——通不过终止性检查的代码根本写不出来。
这两个身份不是拼接，而是同一件事的两面：正因为每个程序都保证终止、每次等式推理
都可机械化验证，「类型检查 = 证明检查」才是可信的。本章不深入任何语法细节，只把
这三件事装进你的脑子：**Curry–Howard 直觉、终止性检查的存在主义、以及新手在
第一个文件上必撞的三道门**——最后一件事靠把 01 章示例故意跑翻车来完成。

对应示例：`../examples/Ex01_intro.agda`

## 1.1 Agda 的双重身份

**身份一：证明助手。** 你在 Agda 里定义数据（自然数、列表、语法树……都是定义出来
的，不是内建的）、陈述命题、然后给出证明。与 Coq 用 tactic 脚本「指挥证明」不同，
Agda 的主流方式是**直接构造证明项**，Emacs 里用孔洞（hole）把「还不会写的位置」
标出来，边看类型边填——像填空，不像指挥（02 章实测这套工作流）。

**身份二：total 函数式语言。** Agda 语法酷似 Haskell（01 章示例里你会看到熟悉的
函数定义方式），而且真的能编译执行：`--compile` 走「Agda → Haskell → GHC →
机器码」流水线（02 章实测，最小 IO 程序约一两分钟出可执行文件）。区别在于 Haskell
接受任何能过类型检查的程序（包括死循环），Agda 只接受**同时过类型检查和终止性
检查**的程序。

三个先入为主的澄清，帮你摆正期待：

1. **Agda 不自动证明定理**。它是一台严格的检查机器，证明思路永远是您的活；
2. **不能随手写不终止的程序**（见 1.3 节），「先写个 while 循环试一下」在这里
   不存在——这不是缺陷，而是它可信度的来源；
3. **报错信息是它最丰富的反馈渠道**。学会读报错（文件位置 + `[错误标签]` +
   语境行）等于学会了一半 Agda，本教程每个坑位都附真实报错原文。

验证方式贯穿全书：每章示例都必须让下面命令以退出码 0 收场——

```bash
cd agda && agda examples/Ex01_intro.agda
```

## 1.2 Curry–Howard：命题即类型，证明即程序

Agda 一切魔力的地基是 **Curry–Howard 对应**：逻辑世界和类型世界是同一张地图。
Agda 里最常用的一版对照表（Unicode 符号后括号给 ASCII 输入法，\ 开头是 Emacs
输入序列的前缀）：

| 逻辑世界 | Agda 类型世界 |
|---|---|
| 命题 P | 一个类型（`Set` 宇宙里的成员，读作「P 的证明们」） |
| P 成立 | 类型 P **有居民**：写得出一个值 `p : P` 的完整定义 |
| 蕴含 P → Q | 函数类型 `P → Q`（ASCII `->`） |
| 「P 且 Q」 | 记录类型 `P × Q`（ASCII `\times`，匿名写作 `(p , q)`） |
| 「P 或 Q」 | 和类型 `P ⊎ Q`（ASCII `\uplus`） |
| 真 / 假 | `⊤`（空记录） / `⊥`（无子句的数据） |
| ∀ x ∈ A. P x | 依赖函数类型 `(x : A) → P x` |
| ∃ x ∈ A. P x | 依赖对 `Σ[ x ∈ A ] P x` |
| 等式 a ≡ b 的证明 | `refl`（当两边算到同一个值时） |

「证明 = 函数」不是修辞，是字面意义。看本章示例里的前两个定义
（`../examples/Ex01_intro.agda`，与文件逐字一致）：

```agda
-- 恒等函数「顺便」证明了「A 蕴含 A」；
-- 类型 {A : Set} → A → A 读作「对任意类型 A，A → A 成立」。
identity : {A : Set} → A → A
identity x = x

-- modus ponens（肯定前件）：「P 蕴含 Q」加上「P 成立」得到「Q 成立」——
-- 逻辑推理就是函数应用。
modus-ponens : {P Q : Set} → (P → Q) → P → Q
modus-ponens f p = f p
```

`modus-ponens` 的函数体 `f p` 就是推理规则本身的应用——在别的语言里这叫
「组合两个函数」，在这里这叫「构造一个证明」。

等式证明更玄一点：Agda 的内建命题等式 `_≡_`（ASCII `\==`）里，**`refl` 是唯一的
构造子**，但它能过关的条件不是「两边长得一样」，而是「两边**归约**到同一个值」：

```agda
-- 一个具体的等式证明。证明体只有 refl 一个词：
-- 因为 2 + 3 会归约（计算）成 5，两边「定义相等」，refl 即可。
-- 交互式会话里的 Compute (2 + 3) 得到的 = 5，在这里等价于：
_ : 2 + 3 ≡ 5
_ = refl
```

也就是说，**在 Agda 里「算」和「证明」是同一个动作的两副面孔**：类型检查器为了
验证 `refl`，被迫真的去计算了 `2 + 3`。前面表里「把定理用起来」的示范：

```agda
-- 把上面两个「定理」用起来，证明才算「被使用」：
_ : 2 + 3 ≡ 5
_ = modus-ponens identity refl
```

但 refl 不是万能钥匙——它对「含变量的等式」立刻缴械（实测报错）：

```agda
bad : ∀ n → n + 0 ≡ n
bad n = refl
```

```text
error: [UnequalTerms]
n + 0 != n of type ℕ
when checking that the expression refl has type n + 0 ≡ n
```

`n + 0` 里 `n` 是未知量，无法归约到 `n`。这条等式是 13 章归纳证明的第一个正式
定理。记住分野：**refl 管「算得出来」的等式，归纳管「对所有输入」的等式**。

## 1.3 终止性检查：一门不许你写死循环的语言

Agda 每个函数定义都必须通过**终止性检查**：递归必须对某个「结构上变小」的参数
进行。这不是风格洁癖，而是逻辑自洽的生死线——在不终止的体系里，`loop n = loop n`
这类函数可以作为任何命题的证明（包括假命题），整个「类型即命题」的大厦瞬间塌掉。
所以 Agda 直接拒绝。新手第一次撞墙的真实体验（复现文件放在临时目录跑）：

```agda
module BadRec2 where

open import Data.Nat using (ℕ; _+_)

loop : ℕ → ℕ
loop n = loop n
```

```text
Checking BadRec2 (/tmp/agda-proj/examples/BadRec2.agda).
/tmp/agda-proj/examples/BadRec2.agda:5.1-6.16: error: [TerminationIssue]
Termination checking failed for the following functions:
  loop
Problematic calls:
  loop n
    (at /tmp/agda-proj/examples/BadRec2.agda:6.10-14)
```

读一下这份报错：范围 `5.1-6.16` 覆盖整个定义，`Problematic calls` 精确点名
「自我调用」——错误标签 + 问题调用，是 Agda 报错里质量最高的一类。

与 Haskell 的对照：同样的代码在 GHC 里类型检查、编译、运行（然后挂死）全部合法；
与 Coq 的对照：Coq 的 `Fixpoint` 也要求结构递归，但社区常靠 `fuel`/`Acc` 绕行，
Agda 的社区文化则更「认命」——终止不了通常说明命题该改。

**逃生门**一共三道，本教程只在讲清「代价」的前提下演示：

1. **`postulate`：承认存在，不给实现。** 唯一能「合法地不计算」的声明——
   你引入公理，定理变成「公理 ⇒ 定理」。本章示例真的用了：

   ```agda
   -- 终止性检查不允许我们写「算不出结果」的函数，
   -- 但 postulate 允许我们不给出任何实现就承认一个居民存在。
   -- 下面的 magic 没有任何计算内容——它是我们「假设」出来的自然数。
   postulate
     magic : ℕ

   -- postulate 出来的东西照样参与类型推理：自反性仍然成立。
   _ : magic ≡ magic
   _ = refl
   ```

   代价：`magic` 没有任何计算内容，谁真想把它「算出来」谁扑空——这是公理的代价；
   严肃开发可用 `{-# OPTIONS --safe #-}` 整体禁用 postulate
   （`--help` 原文：disable postulates, unsafe OPTION pragmas…）。
2. **`--guardedness`：无限对象的正门。** 流、协归约数据不被看作「不终止」而是
   「有产出的无限过程」，需要文件首行开 `{-# OPTIONS --guardedness #-}`
   （02、22 章实测；忘开是新手高频事故，报 `[InfectiveImport]`）。
3. **`{-# TERMINATING #-}` Pragma / `--no-termination-check`：自毁大门。**
   实测在 `loop` 上挂 pragma 后检查直接通过——此时 Agda 不再为一致性背书，
   你可能「证明」出 `⊥`。本教程除展示报错外不使用。

## 1.4 与 Coq / Lean 4 / Idris 的关系

同为依赖类型语言家族，日常手感差异比理论基础差异大：

| | Agda 2.8 | Coq/Rocq | Lean 4 | Idris 2 |
|---|---|---|---|---|
| 理论基础 | Martin-Löf 类型论 (MLTT) | 构造演算 (CIC) | 类型论 + 饱和数学库 | MLTT |
| 证明风格 | **交互式项构造**（孔洞 + 类型视图） | tactic 脚本为主 | 项 + tactic 混合，自动化强 | 项构造 + 少量 tactic |
| 终止性 | **强制**，默认不可关 | 结构递归要求（可 fuel 绕） | `partial` 默许，终止可选 | 强制（支持 sized types） |
| 落地方式 | 编译为 Haskell→GHC 机器码 | Extraction 到 OCaml/Haskell | 原生编译，兼作通用语言 | 编译到 Scheme/JS 等 |
| 生态气质 | 类型论研究 + 依赖编程教材派 | 老牌 CS 形式化（CompCert） | 数学界新宠（mathlib） | 小而美 |
| 交互环境 | Emacs agda2-mode 一枝独秀 | VSCode 等多元 | VSCode 一等公民 | 编辑器较弱 |

如果你跟过同系列的 [coq](../../coq/README.md) 教程：Curry–Howard 心智模型 100%
复用，差别集中在「Coq 用策略造项，Agda 直接写项」与「Agda 的终止检查严得多」。
如果从 Agda 入坑，转别的助手都轻松；反过来会不太习惯「可以写不终止程序」的世界。

## 1.5 简短历史

- **理论根**：1972 年前后 Per Martin-Löf 提出直觉主义类型论（MLTT），把「证明是
  构造」的 Brouwer–Heyting–Kolmogorov 解释落进类型系统——Agda 直接沐浴在这一
  血统下，这也是它的等式/逻辑库如此「按命题思考」的原因；
- **系统诞生**：1990 年代末，瑞典人 **Ulf Norell** 在哥德堡的查尔姆斯理工大学
  （Chalmers）开始 Agda 项目，2005 年前后推倒重写为今天的体系，其 2007 年博士
  论文 *TypeError – Dependently Typed Programming* 是依赖编程的奠基文献之一。
  名字取自 19 世纪诗人/数学家 **Ada Lovelace** 名字的变体拼写；
- **成形**：Andreas Abel 长期主持核心与元理论（立方类型论 24 章即其脉络），
  Nils Anders Danielsson 主导的标准库从 2010 年起成为「依赖类型编程教科书的
  参考实现」——本教程用的 stdlib 2.3 就是该库的 Debian 发行版（27 章讲组织法）；
- **现状**：Agda 由 Chalmers 团队持续发布，本书钉在 **2.8.0**（apt 发行版，
  实测 `agda --version` 输出见 02 章）。

## 1.6 第一个文件：三道门与一个故意撞的坑

本章示例 `Ex01_intro.agda` 的**文件名本身就是一门课的讲义**——为什么不是
`01_intro.agda`？因为第一个坑叫**模块名不能以数字开头**。Agda 的顶层模块名与
文件同名同姓（第二道门），而 `01` 在 Agda 的词法里是数字字面量。实测撞墙：

```agda
module 01_intro where
```

```text
/home/xulun/code/programming/agda/examples/01_intro.agda:1.17: error: [ParseError]
in the name 01_intro, the part 01 is not valid because it is a literal
```

于是全书统一 `Ex` 前缀（README 亦约定「章号 = 示例编号」）。第二道门：**顶层
模块名必须等于文件名**。写 `module WrongName` 放进 `TmpCh02Wrong.agda`（实测
报错，注意候选列表被 include 路径里的标准库污染，显得特别长）：

```text
/home/xulun/code/programming/agda/examples/TmpCh02Wrong.agda:1.8-17: error: [ModuleNameDoesntMatchFileName]
The name `WrongName` of the top level module does not match the file
name. A such named module should be defined in one of the following files:
  /home/xulun/code/programming/agda/examples/WrongName.agda
  ...
  /usr/share/agda-stdlib/src/WrongName.agda
  ...
```

第三道门：**`import` 不等于 `open`**。Haskell 习惯「import 即所用」，Agda 的
`import` 只把模块挂上限定名；`open import` 才把名字倒进当前 scope。实测：

```agda
module TmpCh02Imp where
import Data.Nat

_ : 2 + 3 ≡ 5
_ = refl
```

```text
error: [NotInScope]
Not in scope:
  +
  at /home/xulun/code/programming/agda/examples/TmpCh02Imp.agda:4.7-8
    (did you mean 'Data.Nat._+_'?)
when scope checking +
```

`(did you mean 'Data.Nat._+_'?)`——Agda 把答案塞在你脸上。本章示例统一用
`open import Data.Nat using (ℕ; _+_; _*_)` 这种「开而不滥」的写法，08 章起
是标准姿势。

## 1.7 怎么读这本教程

- **章号 = 示例编号**：每章开头一行「对应示例」，示例文件都在 `../examples/`，
  每份都以 2.8.0 + stdlib 2.3 验证过退出码 0。先跑示例、再读正文，卡住先查
  [28 章坑清单](28-pitfalls.md)；
- **学习路线**（README 同款）：01–04 上手与记号 → 05–10 数据建模与依赖类型 →
  11–18 证明主线（等式/逻辑/归纳/推理/判定/Vec/同构/代数）→ 19–24 工程专题 →
  25–26 综合实战 → 27–28 手册化收尾；
- 工具链细节（命令行、`.agda-lib`、Emacs 键位）全在下一章，**02 章之后你才真正
  需要 Emacs**；1 章靠命令行就够；
- Unicode 不是摆设：`ℕ ≡ ⊎ Σ → ∀` 都是 `\` 输入法打出来的（Emacs agda-input，
  首次出现会给 ASCII 对照；04 章专讲记号）。

## 1.8 坑位清单（本章实测）

1. **模块名不能以数字开头**：`module 01_intro` 直接 `[ParseError]`，全书因此用
   `ExNN_name` 命名（报错原文见 1.6 节）；
2. **顶层模块名必须与文件名一致**：不一致报 `[ModuleNameDoesntMatchFileName]`
   并甩出一长串候选路径（include 里有标准库时更吓人，但都只是「改名字」的事）；
3. **`import` 不带 `open`，名字进不了 scope**：`+` 等运算符会伪装成「未定义」，
   `[NotInScope]` 的 did-you-mean 是真提示；
4. **refl 只对可判定等式生效**：`n + 0 ≡ n` 用 refl 会撞 `[UnequalTerms]`
   `n + 0 != n of type ℕ`——含变量的等式请走 13 章归纳；
5. **终止性错误是特性不是 bug**：`[TerminationIssue]` 的「Problematic calls」
   点名自我调用；三道逃生门（postulate / --guardedness / pragma）各有代价，
   pragma 门会出卖一致性，CI 建议 `--safe`；
6. **postulate 悄悄改变定理的含义**：它不报错、不警告，只是让「证明」的根基从
   计算挪到假设。审查一个 Agda 库的可靠第一步：`grep -rn "postulate" 源码/`。

---
下一章：[02 · 工具链与交互方式](02-toolchain.md) ｜ 返回：[README](../README.md)
