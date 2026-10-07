# 01 认识类型论：从悖论到四大证明助手

> 本章对应读本：Nederpelt & Geuvers《Type Theory and Formal Proof》前言与第 1 章；
> 《现代类型论的发展与应用》1.1–1.2；Farmer《Simple Type Theory》第 2 章；
> Hindley《Basic Simple Type Theory》导言。
> 代码示例：`examples/01_intro/`（Coq / Agda / Lean 各一）。

## 1.1 类型论要解决什么问题

类型论（type theory）是一门把**「项—类型」的分层**当作出发点的数学基础语言。
它的诞生动机很直接：19 世纪末的朴素集合论出了悖论。

> **罗素悖论**（见《现代类型论的发展与应用》1.1 节）：令
> `R = { x | x ∉ x }`。若 R ∈ R，按定义得 R ∉ R；若 R ∉ R，又得 R ∈ R。
> 两个方向都矛盾。

罗素把悖论的根源归结为**恶性循环**：用「所有集合的总体」再去定义新的集合。
他的解法是**分层**：每个集合都活在一个明确的层级上，`x ∈ y` 只在
`y` 的层级比 `x` 高一时才有意义。`R ∈ R` 这类陈述从一开始就不合语法。
这套「简单类型论」的雏形（Russell 1908，经 Chwistek、Ramsey 简化）后来被
Church（1940）用 λ 记号重写为今天的形式——**简单类型 λ 演算 λ→**，
这是本指南第 2–5 章的主角。

与罗素的类型论平行发展的还有两条路：Zermelo 的**公理化集合论**
（保留「无类型的一阶逻辑 + 分离公理限制」）和 Hilbert 学派的**一阶逻辑**。
今天主流数学建立在它们之上。那为什么还要类型论？Farmer《Simple Type
Theory》第 2 章的五个问答值得整段转述（意译）：

| 问题 | Farmer 的回答（要点） |
|---|---|
| Why logic? | 数学推理需要一种精确语言来消歧 |
| Why a **practical** logic? | 一阶逻辑表达数学时需要把函数、数、集合都编码进一个论域，笨拙且易错 |
| Why **simple type theory**? | 类型直接对应数学的分层（数、函数、函数的函数……），语法则简单得多 |
| Why not first-order logic? | FOL 里「函数应用于参数」不是内建的，要么编码为关系，要么带上未定义性 |
| Why not set theory? | 集合论里一切都是集合，`3 ⊆ sin` 之类无意义陈述并不被类型系统拒绝 |

第三个没列进表的问答是 *Why not dependent type theory?*——Farmer 的回答是
「简单类型论够用且语义更干净」。对一本以**程序与证明**为主线的指南来说，
答案恰恰相反：**依赖类型**正是我们要去的地方——但在那之前，
简单类型论是必经的地基。

**一句话总结三套基础的分工**：

- **一阶逻辑 + 集合论**：一个无类型的论域，靠公理限制回避悖论。证明与计算分离。
- **简单类型论**：语法上分层，`f : A → B` 里 `A`、`B` 是类型。命题与证明分离（逻辑是外挂的）。
- **依赖类型论**：类型里可以出现项（`Vec A n`），于是命题可以作为类型、证明作为项——**逻辑内生于类型系统**。

## 1.2 三条历史主线

### 主线一：λ 演算与简单类型（Church，1930s–1940s）

Church 为给数学提供一个可计算的基础发明了无类型 λ 演算；它本身不一致
（Kleene–Rosser 悖论），Church 随即引入类型层级得到 λ→（*A Formulation of
the Simple Theory of Types*, 1940）。λ→ 的项要么有类型要么不可构成，
罗素悖论的 `R ∈ R` 在语法层面就写不出来。

### 主线二：Curry–Howard 对应（1934/1958/1969）

Curry 在 1934 年注意到组合子 `K`、`S` 恰好是命题逻辑公理
`A → B → A`、`(A → B → C) → (A → B) → A → C` 的「证明」；
1958 年他进一步把「程序构造」与「演绎」对应起来。Howard 1969 年的手稿
（1980 年才发表）把这个观察扩展到整个直觉主义自然演绎：

> **命题即类型（propositions as types），证明即程序（proofs as programs）。**
> 蕴涵 `A → B` 就是函数类型；**全称量词**就是依赖函数类型 `Π`；
> 合取 `A ∧ B` 就是乘积类型；析取就是和类型；**假**就是空类型。
> 逻辑的**引入规则**是类型的**构造子**，**消去规则**是类型的**消去子**。

第 5 章将逐步展开这条对应。它是整个「证明助手」产业的根基。

### 主线三：Martin-Löf 直觉主义类型论（1971–1984）

Martin-Löf 想给构造性数学一个基础：数学对象与证明必须能**构造**出来，
存在断言必须携带见证。他的类型论（MLTT，先后有 1971 逻辑型、1979 直觉型、
1984 外延型等版本）把依赖类型做成了一等公民，判断形式共四种：

```
A type                A 是一个类型
A ≡ B                 A 与 B 定义相等
a : A                 a 是 A 的居留项
a ≡ b : A             a 与 b 是 A 中定义相等的居留项
```

Nordström–Petersson–Smith《Martin-Löf 类型论程序设计导论》（本指南第
10–16 章的主要读本）就是这一形式系统的教科书式展开。

在这三条主线上继续向前：

- **Coquand & Huet（1985）**把 Church 的 λ→ 与 Girard 的 System F、以及
  依赖类型统一成**构造演算 λC**（Calculus of Constructions）——Barendregt
  λ 立方体的顶点（第 6–8 章）。
- **Coq**（1989–）内核即 λC 加归纳类型（CIC）；**Agda**（1990s–）直接把
  MLTT 做成编程语言；**Lean**（2013–）在 Coq 风格内核上重做了元编程与
  自动化生态（第 17 章）。
- **Voevodsky**（2006–2013）发现 MLTT 的相等类型可以解读为**同伦**，
  「等价的类型相等」（泛等公理）打开了同伦类型论（HoTT）——
  第 19–23 章。

## 1.3 四大实现一览

本指南的代码横跨四个系统。先给一张总表，细节随后各章展开：

| | Coq 8.20 | Agda 2.8 | Lean 4 | Coq-HoTT |
|---|---|---|---|---|
| 内核 | CIC（λC+归纳+Prop/Type） | MLTT（+大小无关的宇宙塔） | CIC 变体（+Quot） | MLTT+泛等+HIT |
| 命题 | 独立 `Prop` 宇宙 | 无专门命题层：命题即类型 | `Prop = Sort 0` | 类型即空间 |
| 证明写法 | tactic 为主，项式可选 | 纯项式（模式匹配），无 tactic | tactic/项式混用，可扩展 tactic | 同 Coq，但依赖库记号 |
| 相等 | `eq` + Leibniz 外延 | `_≡_`（`--without-K` 可关 J） | `Eq`（内核 `Eq.rec`） | `paths`（同伦） |
| 终止性 | Fixpoint 结构递归检查 | 全局终止检查器 | 结构/良基递归检查 | 同 Coq |
| 命令行 | `coqc` | `agda` | `lean` / `lake` | `coqc` |

> **本指南对 Coq-HoTT 的处理**：官方 HoTT 库（582 个 `.v`）不在本机工具链内。
> 第 19–23 章采用**自包含 mini-HoTT** 策略——用普通 `coqc` 从零定义路径
> 类型、J、transport、泛等公理与 HIT 公理化模拟。这在教学上反而更贴近
> HoTT 书的做法：每一条公理与规则都是显式引入、显式计数的。

## 1.4 工具链与验证通道（本机实测）

```text
Coq   : coqc 8.20.1（Windows，PATH 直接可用）
Agda  : agda 2.8.0 + stdlib 2.3（WSL Ubuntu-26.04；
        Debian 打包把预编译 .agdai 放在 _build/ 下与 src/ 分离，
        已合并进 /usr/share/agda-stdlib/src，首次加载约 5 秒）
Lean  : lean 4.25.0（Windows，standalone 单文件直跑，不用 lake/Mathlib）
```

全部示例由 `build.ps1` 三通道验证：

```powershell
cd G:\code\guide\typetheory
pwsh -NoProfile -Command '& ./build.ps1 -All'      # 全量
pwsh -NoProfile -Command '& ./build.ps1 -Chapter 01' # 单章
pwsh -NoProfile -Command '& ./build.ps1 -Lang agda'  # 单语言
```

三个通道的判定标准（详见脚本头注释）：退出码 0、输出无 error/warning、
Coq 侧 stderr 无 `Error`。文件命名 `exNN_*.v|.agda|.lean` 是三家共同的
安全区——Coq 8.20 与 Agda 都不接受数字开头的模块名（实测：Agda 报
`InvalidFileName`，Coq 报 `Invalid character '0'`；故 build.ps1 对 Coq
再拷贝一层 `ex_` 前缀纯属保险）。

## 1.5 第一个对照实验：`n + 0 = n`

四个系统里写同一个定理，「类型」的样子一目了然。

### Coq（tactic 式）

```coq
Theorem plus_n_O_tactic : forall n : nat, n + 0 = n.
Proof.
  induction n as [| n IH].
  - reflexivity.            (* 0 + 0 ≡ 0：定义相等 *)
  - simpl. rewrite IH. reflexivity.
Qed.
```

`forall n : nat, n + 0 = n` 是 `Prop` 宇宙里的一个类型；`Proof...Qed`
之间发生的事只是在构造这个类型的居留项。tactic 是「构造过程」的命令行
界面——它不是逻辑的一部分。

### Coq（项式，同一定理零 tactic）

```coq
Fixpoint plus_n_O_term (n : nat) : n + 0 = n :=
  match n with
  | O => eq_refl 0
  | S n' => @f_equal nat nat S (n' + 0) n' (plus_n_O_term n')
  end.
```

`eq_refl` 是相等类型的唯一构造子（`x = x` 的居留项），
`f_equal` 是合同性（congruence）：从 `a = b` 得 `f a = f b`。
这就是证明的「真身」——一个结构递归函数。

### Agda（纯项式）

```agda
plus-zero : (n : ℕ) → n + zero ≡ n
plus-zero zero    = refl                    -- 定义相等自动折叠
plus-zero (suc n) = cong suc (plus-zero n)  -- 合同性
```

Agda 没有 tactic 层；模式匹配就是证明的全部。`refl` 要求两边
**定义相等**（convertible）：`zero + zero` 按 `_+_` 的定义递归到 `zero`，
所以第一行成立。注意：这里 Coq 的 `simpl` 对应 Agda 里什么也不用做——
`_+_` 在两个系统里都定义在第一个参数上，`suc n + zero` 已经**可转换地**
等于 `suc (n + zero)`。

### Lean 4（两种写法并排）

```lean
theorem lean_rhs_zero : ∀ n : Nat, n + 0 = n := fun _ => rfl

theorem lean_lhs_zero : ∀ n : Nat, 0 + n = n := by
  intro n
  induction n with
  | zero => rfl
  | succ n ih => exact congrArg Nat.succ ih
```

第一行能一行 `rfl` 过，第二行却要归纳——**与 Coq/Agda 正相反**。
原因藏在 `Nat.add` 的定义里：Lean 4 的加法递归在**第二个**参数上
（`n + 0` 直接折叠为 `n`），而 Coq 的 `plus` 与 Agda 标准库的 `_+_`
都递归在**第一个**参数上（`0 + n` 才直接折叠）。哪一侧递归，
哪一侧就「按定义相等」免费成立，另一侧就得归纳证明。定义相等的
方向性，从第一页起就在支配我们。

### 看出什么了？

1. **定理的类型四处一致**：`∀ n, n + 0 = n`。差异全在「怎么构造居留项」。
2. **每个证明都是普通程序**：由 `refl`（ reflexivity）、`cong`（congruence）、
   递归消去子三种原料构成——这三种原料恰好对应相等类型的
   **构造规则、合同性、归纳原理**。
3. **定义相等（definitional equality）是隐性主角**：`suc n + 0` 为什么能
   「当作」`suc (n + 0)`？因为加法的定义就长那样。第 10 章会把
   `a ≡ b : A` 这种判断形式正式化。

## 1.6 全书路线图

```text
第一部分  简单类型论（02–05）
  02 无类型 λ 演算        项、α/β/η、Church–Rosser、范式       [Hindley 1; TTAFP 1]
  03 简单类型 λ→          Church 式类型规则、推导树、SN         [TTAFP 2; TAPL 9]
  04 Curry 式类型指派     TA_λ、合一、主类型算法（HM 之根）     [Hindley 2–3]
  05 Curry–Howard         蕴涵逻辑 ↔ λ→，组合子 K/S             [Hindley 6]
第二部分  λ 立方体（06–09）
  06 System F λ2          多态、Church 编码                    [TTAFP 3]
  07 依赖类型 λP          类型依赖项、逻辑框架 LF               [TTAFP 4]
  08 λω 与 λC             类型依赖类型、构造演算、Barendregt 立方体 [TTAFP 5–6]
  09 定义与证明工程       λD 精神：定义/缩写/局部性             [TTAFP 8–11]
第三部分  Martin-Löf 类型论（10–16）
  10 判断与规则           四种判断、一般规则、语境               [Nordström 4–5]
  11 Π 与枚举集合         ∅/⊤/Bool、case 分析                   [Nordström 6–7]
  12 相等类型             内涵/外延、J、等式定律                 [Nordström 8]
  13 归纳类型族           ℕ/列表/Σ/不交和、四方同证              [Nordström 9–13]
  14 全域与层级           U₀:U₁:…、Girard 悖论                   [Nordström 14]
  15 W 类型与良序         归纳定义的表达力                       [Nordström 15–16]
  16 子集与子类型         子集类型、强制子类型                   [Nordström 17–18; 现代 2.5]
第四部分  证明助手实战（17–18）
  17 四大助手对照         同一开发流四家走一遍
  18 程序即证明          抽取、编译、证明无关性
第五部分  同伦类型论（19–23）
  19 路径与同伦           恒等类型的同伦解读、transport         [HoTT 1–2]
  20 泛等公理             等价即相等、结构搬运                   [HoTT 2]
  21 截断层级             h-level、命题/集合/群胚               [HoTT 3]
  22 高阶归纳类型         区间、圆、商                          [HoTT 6]
  23 综合实战             π₁(S¹)=ℤ 编码-解码                    [HoTT 8]
第六部分  收束（24–25）
  24 元理论总览           Church–Rosser、SN、一致性、主体归约
  25 坑位清单与书目导读   四家差异速查、七本书怎么读
```

## 1.7 记号约定

本指南统一用下列记号（与四家的按键映射一并列出）：

| 概念 | 本指南 | Coq | Agda | Lean |
|---|---|---|---|---|
| 函数类型 | `A → B` | `A -> B` | `A → B` | `A → B` |
| 依赖函数 | `Π (x:A). B` | `forall x:A, B` | `(x : A) → B` | `(x : A) → B` |
| 乘积 | `A × B` | `A * B` | `A × B` | `A × B` |
| 依赖对 | `Σ (x:A). B` | `{x : A & B}` / `sig` | `Σ[ x ∈ A ] B` | `Σ x : A, B` |
| 相等 | `a = b` | `a = b` | `a ≡ b` | `a = b` |
| λ 抽象 | `λx. t` | `fun x => t` | `λ x → t` | `fun x => t` |

Unicode 输入：Agda/Lean 原生支持（Lean 里 `\to` 打 `→`、`\bbN` 打 `ℕ`）；
Coq 源码里 `->` 即可，本文叙述用 Unicode 简写。

## 本章小结

- 类型论用**语法分层**替代集合论的**公理限制**来规避悖论。
- 三条历史主线汇成一个产业：λ 演算（计算）× Curry–Howard（对应）×
  MLTT（依赖类型）→ Coq / Agda / Lean / HoTT。
- 同一个定理 `n + 0 = n` 在四家写出来都是「用 `refl`、`cong` 和递归
  消去子拼一个程序」——证明即程序不是口号，是可以 `Print` 出来看的东西。

> **坑位速记**（详细清单见 25 章）
> ① Coq 8.20 与 Agda 都不接受数字开头的文件名/模块名；
> ② Lean 的 `Nat.add` 递归在**第二个**参数上：`n + 0 = n` 全程 `rfl`，
> `0 + n = n` 反而要归纳——与 Coq/Agda（加法递归在第一参数）正相反；
> ③ Agda 2.8 起 `Set₁` 等记号是内建语法，`Agda.Primitive` 不再导出
> （`open import Agda.Primitive using (Set₁)` 会告警）。

---

下一章：[02 无类型 λ](02-lambda.md)
