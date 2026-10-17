# 53 高阶归纳类型：造空间的粘合剂

> 对应读本：HoTT 书第 6 章全部（引言、归纳原理与依赖路径、
> 区间、圆与球面、** Suspension**、胞腔复形、**hubs-spokes**、
> **Pushout**、截断、商、代数、**flattening 引理**、一般语法）；
> coq-hott 教程 12–13、16 章。代码：`examples/53_hit/`——
> **Coq 公理对照组**（区间、圆、商三件套，账目公开）+
> **cubical Agda 深化件 `ex53_hitc.agda`**（Suspension/Pushout
> 是真 data——消去子与计算规则由模式匹配派生；S¹ = Susp Bool
> 的「生产线」；Interval = Pushout 样本；loop 的两行定义）。

## 53.1 HIT 是什么：构造子可以是「路径」

普通归纳类型的构造子造**点**；HIT 允许构造子造**路径**（乃至
更高维）：

```text
区间 I   构造子：zero, one : I；seg : zero == one
圆 S¹    构造子：base : S¹；loop : base == base
商 A/R   构造子：qg : A → A/R；qglue : qg x == qg y（xRy 时）
```

这补齐了类型论「造空间」的最后一块：拓扑粘合（把区间两端
粘起来得圆；把整段整段的点等同起来得商）。

## 53.2 消去子：签名里的「路径构造子条款」

HIT 的归纳原理在普通归纳原理之外多出**路径条款**：

```coq
Axiom interval_rec : forall (Q : interval -> Type)
  (u : Q zero) (v : Q one),
  transport Q seg u == v -> forall i, Q i.

Axiom circle_rec : forall (Q : circle -> Type)
  (b : Q base) (l : transport Q loop b == b),
  forall c, Q c.
```

读法：要沿区间定义函数，除了两端各给值，还得给**「两端值沿
seg 搬运后吻合」的证据**——正是 49 章 transport 的用武之地。

**计算规则的分界**（47 章伏笔兑现）：J 在 idpath 上定义性计算；
seg/loop 是公理化的路径（不透明），计算规则只能**公理补账**
（`interval_zero`/`interval_one`/`circle_base`）。Cubical Agda
等系统里这些规则可计算——那才是「原生 HIT」。

## 53.3 商类型：万有性质实测

公理化的商（nat 按 mod 2）：

```coq
Axiom quot_lift : forall (Q : Type) (F : nat -> Q),
  (forall n, F (S (S n)) == F n) -> quot -> Q.
Axiom quot_lift_qg : ... quot_lift Q F cond (qg n) == F n.
```

**尊重等价关系的函数唯一下沉**。实测：奇偶函数 `parityF`
用两步递归定义——条件 `F (S (S n)) == F n` 成为**定义相等**
（免证明！），于是

```coq
Example parity_5 : parity (qg 5) == false2 :=
  quot_lift_qg bool2 parityF (fun n => idpath) 5.
```

这是「定义方式选得好，公理负担就小」的典型现场——对照 19 章
的方向学（加法递归侧）一脉相承。

## 53.4 公理记账：本章的诚实清单

| 公理 | 作用 |
|---|---|
| interval/zero/one/seg + rec + 两条计算 | 区间全套 |
| circle/base/loop + rec + 计算 | 圆全套 |
| quot/qg/lift/qg 计算 | 商全套 |
| `Print Assumptions parity_5` | 逐条公示 |

Cubical 系统的意义就在这张表：**把公理变成可计算规则**
（ua 与 HIT 的计算全交给立方演算的 kan 操作）。

> **坑位速记**
> ① 公理化 HIT 的 `ap f loop`-型计算规则要用**依赖版 apD**
> 表述（类型随点变的路径作用），非依赖版类型对不上
> （实测 `ap double loop == loop · loop` 两端锚点不一致）；
> ② `transport (fun _ => X) q u == u`（常值族）是 **J-定理**
> 而非定义——q 不透明时 match 卡住，先立引理（25 章形态）；
> ③ 商的条件下沉选「递归结构使条件成为定义相等」的函数
> （两步递归的 parityF），公理用量立减；
> ④ `Definition f (q : Q) := lift ... q` 别忘应用到 q——
> 类型 `Q -> X` 交给 `X` 位的经典报错。

## 53.5 Suspension：球面生产线（书 6.5）

**双锥构造**（suspension）：把 A 的每一点拉成一条南北子午线：

```agda
data Susp (A : Set) : Set where
  north : Susp A          -- 北极
  south : Susp A          -- 南极
  merid : (a : A) → north ≡ south   -- a 的一条子午线
```

消去子的三段式（`Susp-elim`）：两极给值、**每条子午线给一个
方形调整**（PathP 从北值到南值）。函子性一行（`Susp-fun`）：
极点保极点、子午线跟函数走。生产线的本义：

> S⁰ = Bool ⇒ **S¹ = Susp Bool** ⇒ S² = Susp S¹ ⇒ …

圆不再手搓（Coq 组的 base/loop 公理化 vs cubical 组的 north/
merid 数据——同一数学的两种身份）。书 6.5 的定理（Susp 的
连通性提升、Susp A 的 Ω 与 A 的悬挂同调）在 55 章展开。

## 53.6 Pushout：粘合的万有构造（书 6.8）

span B ←f— A —g→ C 的**推挤**（pushout）——把 B 与 C 沿 f、g
的像粘起来：

```agda
data Pushout (f : A → B) (g : A → C) : Set where
  inl : B → Pushout f g
  inr : C → Pushout f g
  push : (a : A) → inl (f a) ≡ inr (g a)   -- 粘合路径
```

`Pushout-elim` 三段式同构于 Susp（push 方块调整）。两个样本：

- **区间 = Pushout of 1 ← 1 → 1**（书 6.8 例 1；深化件给出
  inl/inr/push 的三件）：粘合路径就是 seg——53.2 公理化区间的
  pushout 身份揭晓；
- **Susp A = Pushout of 1 ← A → 1**（双点粘合）——生产线与
  粘合机是同一台机器的两个刀头。

Pushout 是 HIT 的「万有构造」：圆、胞腔复形（6.6）、截断
（6.9）、商（6.10）全部能从它加上 higher inductive 递归造出
（书 6.9 的 truncation as pushout——50 章 ∥·∥ 的 pushout 身份）。

## 53.7 hubs 与 spokes、flattening、商（书 6.7/6.12/6.10）

**Hubs and spokes**（6.7）：一组 n-维路径方形可以用「轮毂 +
辐条」替代——一个 hub 点加一组辐条路径（每点一条到 hub），
维数减一代价是点上量化。这是「无限道路构造子」的工程形态，
截断 HIT 的标准内衬。

**Flattening 引理**（6.12）：Σ over a HIT 的计算律——
Σ(w : W). F w 的元素可拉平为（底层 + 每构造子的分量数据的
Σ）推挤。它是 54 章（编码-解码的 code 是 Σ 形）与 55 章
（覆叠空间的「拉平 = 全空间」）的关键预备件——陈述级呈现，
两处用例落地时回看。

**商类型**（6.10）：商 = Pushout 版截断——`quot qg` 的公理化
身份是「加 squash 的 Pushout」。与 25 章（λD 商：把 xRy 造
成定义）对照：λD 商改**定义**（ judgemental），HoTT 商加
**路径**（propositional）——两种「视作相等」的层级差异在两
章并读时最清楚。

## 53.8 区间与函数外延（书 6.3）

区间（I，两端 + seg）的最著名应用：**funext 的证明**——
f ∼ g ⇒ f ≡ g 的路径逐点走 seg（书 6.3.2 的 interval-funext）。
公理化世界（coq-hott 库）用它把「函数外延公理」降格为定理；
cubical 世界里区间被**内建区间 I 吸收**（funext = λ i j → h j i
——59 章一行）。三个世界的接力：公理（mini-HoTT 49 章组）→
定理（interval 构造）→ 定义（cubical 转置）。

## 53.8b HIT 的一般语法与边界（书 6.13）

书 6.13 给出 HIT 声明的一般语法（构造子可为点、路径、方形…
每维一段），并划定边界：**不是所有「看起来合理」的 HIT 都有
模型**——构造子的「严格性」要求（计算规则只在点构造子上）
与一致性共存是一道细线。cubical Agda 把它工程化：data 声明
里路径构造子（IApply）合法、且自动推导相容的消去子——本书
两章（50 章 squash、本章 merid/push）的全部实践都在这条线
的安全侧。更激进的形式（quotient inductive types、two-level
type theory）是活跃的研究前线——58 章结尾再访。

## 53.8c 截断的 Pushout 身份（书 6.9 的合流）

50 章的 ∥·∥（命题截断）在 pushout 视角下有第二种身份：
**∥A∥ = Pushout of 1 ← A → 1**（把 A 的所有点粘成一点——
squash 的粘合解读）！验证（消去子的三段式对照）：point 分支
给目标值、A 的每个元素给一条到该值的粘合路——恰是
∥∥-rec 的签名。推广：**∥A∥ₙ = (n+1)-维版本的迭代粘合**
（书 6.9 的一般 n-截断作为 higher inductive 递归）。「压缩
信息的截断」与「粘合空间的 pushout」是同一操作的语义面与
语法面——50 与 42 两章在此正式合流。机器面对照：50 章的
squash 构造子（data 一行）与本章的 push 构造子（Pushout 的
第三构造子）在消去子上逐字段同构——读者可把两文件并排
验证。

## 53.9 机器面导读

- **Coq（`ex53_hit.v`）**：区间/圆/商三件套的公理化 + 计算规则
  补账 + `Print Assumptions` 逐条公示——「假设世界」的完整
  标本；
- **cubical（`ex53_hitc.agda`）**：Susp（elim+函子）与 Pushout
  （elim+区间样本）的 data 版；S¹ = Susp Bool、S² = Susp S¹
  的生产线；54 章主角 loop 的两行定义
  （`merid false ∙ sym (merid true)`）与幂塔 `loop^`。

---

上一章：[52 归纳进阶](52-induction.md) · 下一章：[54 压轴：π₁(S¹)](54-capstone.md)
