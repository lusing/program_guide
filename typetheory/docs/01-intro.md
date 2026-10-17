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
这是本指南第 2–8 章的主角。

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

第 8 章将逐步展开这条对应。它是整个「证明助手」产业的根基。

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
27–39 章的主要读本）就是这一形式系统的教科书式展开。

在这三条主线上继续向前：

- **Coquand & Huet（1985）**把 Church 的 λ→ 与 Girard 的 System F、以及
  依赖类型统一成**构造演算 λC**（Calculus of Constructions）——Barendregt
  λ 立方体的顶点（第 18–20 章）。
- **Coq**（1989–）内核即 λC 加归纳类型（CIC）；**Agda**（1990s–）直接把
  MLTT 做成编程语言；**Lean**（2013–）在 Coq 风格内核上重做了元编程与
  自动化生态（第 40 章）。
- **Voevodsky**（2006–2013）发现 MLTT 的相等类型可以解读为**同伦**，
  「等价的类型相等」（泛等公理）打开了同伦类型论（HoTT）——
  第 63–74 章。
- 与三条主线并行的是**工业类型系统**：Milner 的类型重构（ML）、
  Cardelli–Wegner 的子类型、Reynolds 的参数化——类型论变成
  编译器里的日常工具。皮尔斯《类型和程序设计语言》（TAPL）是
  这条线的教科书，第 42–58 章按书序走一遍。

## 1.3 四大实现一览

本指南的代码横跨四个系统。先给一张总表，细节随后各章展开：

| | Coq 8.20 | Agda 2.8 | Lean 4 | cubical Agda（--cubical） |
|---|---|---|---|---|
| 内核 | CIC（λC+归纳+Prop/Type） | MLTT（+大小无关的宇宙塔） | CIC 变体（+Quot） | MLTT+泛等+HIT |
| 命题 | 独立 `Prop` 宇宙 | 无专门命题层：命题即类型 | `Prop = Sort 0` | 类型即空间 |
| 证明写法 | tactic 为主，项式可选 | 纯项式（模式匹配），无 tactic | tactic/项式混用，可扩展 tactic | 同 Coq，但依赖库记号 |
| 相等 | `eq` + Leibniz 外延 | `_≡_`（`--without-K` 可关 J） | `Eq`（内核 `Eq.rec`） | `paths`（同伦） |
| 终止性 | Fixpoint 结构递归检查 | 全局终止检查器 | 结构/良基递归检查 | 同 Coq |
| 命令行 | `coqc` | `agda` | `lean` / `lake` | `coqc` |

> **本指南对 HoTT 机器面的处理**：两条通道。**cubical Agda**（WSL
> Agda 2.8 的 `--cubical` 模式）从区间与 Glue 原语手造 transport/
> hcomp/ua——泛等与 HIT **原生计算**（∥·∥ 是真 HIT、J 是两行程序、
> funext 一行），64 章起的主力；**Coq mini-HoTT**（自包含公理化
> 模拟，65–76 章的对照组）用普通 `coqc` 从零定义路径、J、泛等
> 公理与 HIT——每条公理显式引入、显式计数，Hedberg 与 π₁(S¹)
> 的完整机器版在此通道完成。Lean 在 39/46/74 章做 set 层对照
>（Prop=内核化 mere prop、Cantor、实数骨架）。

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
   「当作」`suc (n + 0)`？因为加法的定义就长那样。第 27 章会把
   `a ≡ b : A` 这种判断形式正式化。

## 1.6 全书路线图

```text
第一部分  简单类型论（02–17）
  02–11 证明论线：无类型 λ、η、λ→、Curry 指派、等式语义、
         正规化、Curry–Howard、弱逻辑、逆主类型、居留计数  [Hindley 全书]
  12–17 模型论线：Alonzo、未定义性、证明系统 A、理论与模型、
         理论态射、描述算子                                 [Farmer 全书]
第二部分  λ 立方体与 λD（18–26）
  18–21 System F、依赖类型、立方体、λC 逻辑编码             [TTAFP 1–7]
  22–26 λD 形式系统、旗式自然演绎、λD 数学、Peano→Bézout    [TTAFP 8–15]
第三部分  Martin-Löf 类型论（27–39）                       [Nordström 全书]
  27–33 判断与规则、Π 与枚举、相等与 J、归纳族、全域、
         W 类型、子集与强制（深化轮：natrec 论证、Peano 三副
         面孔、U 与 Peano 4、Smith 独立性、子集合理论 (A′,A″)）
  34    版本史与同一性：四合一判断、Heyting 逐常元、五版本
         演化、证明工具谱系                                 [Nor 1–2]
  35    类型与单型集合 I：元变元、Set/El、类型层 η          [Nor 19]
  36    单型集合 II：常元声明法、Salvesen、操作语义         [Nor 20+附录B]
  37    杂例三讲：half 提取、distr、Bool 限制、强消去       [Nor 21]
  38    程序推导：策略机制、荷兰国旗全程                    [Nor 22]
  39    ADT 规格说明：模块=依赖多元组、参数模、FSET         [Nor 23]
第四部分  证明助手实战（40–41）
  40–41 四家对照、提取与运行
第五部分  程序设计语言的类型论（42–52）                     [TAPL 全书]
  36    操作语义：NB 语言、小步/大步、推导归纳、stuck、安全性 [TAPL 3/4/8]
  37    简单扩展：unit/序列/归属/let/序对/记录/变式/递归/列表 [TAPL 11]
  38    引用与异常：store typing、带状态的安全性              [TAPL 13/14]
  39    子类型：记录宽度深度置换、包含、算法化、合类型        [TAPL 15–17]
  40    命令式对象与轻量级 Java                              [TAPL 18/19]
  41    递归类型：μ、等式/同构、归纳与余归纳、成员算法        [TAPL 20/21]
  42    类型重构：约束、合一、主类型、let 多态                [TAPL 22]
  43    存在类型：pack/unpack、ADT、量词编码                 [TAPL 24]
  44    囿量词：F<:、算法化、不可判定性                       [TAPL 26–28]
  45    类型算子与 Fω：kind、高阶多态、高阶子类型             [TAPL 29–31]
  46    纯函数对象：存在编码的对象与类                        [TAPL 32]
第六部分  现代类型论：UTT 与 MTT 语义学（53–62）           [罗朝晖全书]
  47    UTT 与类型空间：Prop/Type 双层、CN 宇宙、有界量化    [罗 1–2]
  48    强制性子类型：CA/CD、合谐性、保守扩张                 [罗 2.5]
  49    依赖记录与模块：记录类型、栈/数组规范、细化映射       [罗 2.5.3+5.2]
  50    MTT 语义学：通名即类型、选择限制、异义词、事件强迫    [罗 3.1–3.3]
  51    形容词修饰：相交/下属/否定/非承诺/时态五分类          [罗 3.4]
  52    证明无关与驴句：PI、势、计数问题、Most                [罗 3.5]
  53    标记与点类型：语境描述、同谓、集胚                    [罗 4.1–4.2]
  54    判断与事件语义：IS/DO/NOT、异类等式、依赖事件类型     [罗 4.3–4.4]
  55    范畴语法：子结构 λ⊙、Lambek、线性分析                 [罗 4.5+附录E]
  56    LF 与元理论：七性质、逻辑框架、归纳模式、意义理论     [罗 6]
第七部分  同伦类型论（63–74）
  57    路径与同伦：类型即空间                              [HoTT 1–2]
  58    等价论：quasi-inverse 到合同纤维的四定义              [HoTT 4]
  59    泛等公理：等价即相等、UA⇒函数外延                    [HoTT 2]
  60    集合与逻辑：h-level、AC 是定理                       [HoTT 3]
  61    截断与 n-类型：Hedberg、连通性                       [HoTT 7]
  62    归纳进阶：初始代数、恒等系统                         [HoTT 5]
  63    高阶归纳类型：区间、圆、商、粘合                     [HoTT 6]
  64    压轴：π₁(S¹)=ℤ 编码-解码                            [HoTT 8]
  65    同伦论进阶：Freudenthal、van Kampen、Whitehead       [HoTT 8]
  66    范畴论：precategory、Yoneda、SIP、Rezk               [HoTT 9]
  67    集合论：Set 范畴、基数、序数、累积层级                [HoTT 10]
  68    实数：Dedekind vs Cauchy、区间紧性                   [HoTT 11]
第八部分  收束（75–76）
  69    元理论总览：Church–Rosser、SN、一致性、主体归约、不可判定性
  70    坑位清单与书目导读：四家差异速查、八本书怎么读
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

> **坑位速记**（详细清单见 76 章）
> ① Coq 8.20 与 Agda 都不接受数字开头的文件名/模块名；
> ② Lean 的 `Nat.add` 递归在**第二个**参数上：`n + 0 = n` 全程 `rfl`，
> `0 + n = n` 反而要归纳——与 Coq/Agda（加法递归在第一参数）正相反；
> ③ Agda 2.8 起 `Set₁` 等记号是内建语法，`Agda.Primitive` 不再导出
> （`open import Agda.Primitive using (Set₁)` 会告警）。

---

下一章：[02 无类型 λ](02-lambda.md)
