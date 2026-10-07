# 37 时态演绎系统 L

> 对书：Ben-Ari 3e ch14（系统 L 与定理）/ §13.6\*（二值时态算子，文档级）
> 通道：C/L——lth 深嵌入 + lth_sound 可靠性旗舰 + 14.2/14.4 原式推导

39 章解决了「LTL 可满足性怎么**判定**」；本章解决另一个正交的
问题：「LTL 的有效式怎么**证明**」。判定算法对单个公式是终点，
对一族公式没有帮助——当我们要推理「一切满足前提的系统都满足
性质」时，需要的是演算。Ben-Ari 的系统 L 是最小的一套：六条
公理、两条规则，却已经足以承载时态逻辑的全部归纳力量。

## 为什么要公理化（14.1 的立场）

语义方法（模型检查）回答「这个系统满足这个性质吗」，演绎方法
回答「这族假设蕴含这个结论吗」。Ben-Ari 的原话值得记：演绎是
「语义方法失败时唯一的退路」——无穷系统、参数化系统、开放
系统的性质无法枚举状态，只能推导。这与 46 章（霍尔逻辑对
程序验证的角色）完全同构：L 的归纳公理就是不变式方法的
理论化身（下文详述）。

## 系统一览（`ex40_ltlded.v`）

```coq
Inductive lth : lform -> Prop :=
| pK1 : forall a b, lth (lImp a (lImp b a))
| pK2 : forall a b c, lth (lImp (lImp a (lImp b c)) (lImp (lImp a b) (lImp a c)))
| pAnd1 : forall a b, lth (lImp (lAnd a b) a)
| pAnd2 : forall a b, lth (lImp (lAnd a b) b)
| pAndI : forall a b, lth (lImp a (lImp b (lAnd a b)))
| pPair : forall c a b, lth (lImp (lImp c a) (lImp (lImp c b) (lImp c (lAnd a b))))
| pTrans : forall a b c, lth (lImp (lImp a b) (lImp (lImp b c) (lImp a c)))
| lMP : forall a b, lth (lImp a b) -> lth a -> lth b
| lGen : forall a, lth a -> lth (lBox a)
| lGenX : forall a, lth a -> lth (lNext a)
| lDist  : forall a b, lth (lImp (lBox (lImp a b)) (lImp (lBox a) (lBox b)))
| lDistX : forall a b, lth (lImp (lNext (lImp a b)) (lImp (lNext a) (lNext b)))
| lExp   : forall a, lth (lImp (lBox a) (lAnd a (lNext (lBox a))))
| lInd   : forall a, lth (lImp (lBox (lImp a (lNext a))) (lImp a (lBox a)))
| lLin   : forall a, lth (lImp (lNext a) (lNot (lNext (lNot a)))).
```

逐条读出设计意图：

- **命题层**（pK1–pTrans）：Ben-Ari 把「全体命题重言」整体当公理
  （他的 Axiom 0）；机器件取其**构造性子集**——K1/K2 是 05 章
  Hilbert 系统的老朋友，∧ 四式加传递/组装两条工程模式。刻意
  不收 K3（反证式）：它在「语义 = 命题赋值」下经典有效，但
  会让 `Print Assumptions` 的零公理账本破产（lsat 对 □ 是
  无穷量词，不可判定），而本章两条推导恰好不用它——构造性
  子集够用，账本干净。
- **规则**：MP 老面孔；**Gen□**（A ⊢ □A）是 17 章全称推广的
  时态版——注意 `lth` 是**定理式**（无假设上下文），Gen 的
  侧条件「Γ 为空」被类型本身吸收，这是与 17 章 GenMove 公理
  化对照的最干净形态。**GenX**（A ⊢ XA）在 Ben-Ari 书里是
  导出规则；机器件把它提升为原生规则——语义上与 Gen□ 同样
  显然（定理对一切起点成立，故整体后移一步），省去一条
  需要额外公理搭桥的推导（docs 注记此差异）。
- **时态公理五条**：Dist/DistX 是模态分配的时态版（43 章 K
  公理的双胞胎）；**Exp（展开）** `□A → A ∧ X□A` 正是 39 章
  表列 □-规则的公理化——同一数学事实的三种面貌（语义展开、
  表列 α、公理）；**Lin（线性）** `XA → ¬X¬A` 刻画「下一步唯一」
  ——线性时序的本质约束，分支时态（CTL 的 EX）没有它；
  **Ind（归纳）**是系统的灵魂，单独说。

## 归纳公理：不变式方法的理论形态

```
□(A → XA) → (A → □A)
```

读法：「如果 A 的保持（今天真则明天真）是**永远**的，且 A 今天
真，则 A 永远真」。把 A 换成程序不变式：这就是 46/47 章不变式
规则、48 章并发验证的「I 在每条原子步保持」的纯逻辑内核——
工程上的「不变式 + 初始 + 保持 ⟹ 永真」三条义务，在 L 里压成
一条公理。**反方向不成立**：□A 不蕴含 □(A→XA) 的证明确认了
它不是定义而是归纳原理——归纳公理把「有穷步的保持验证」兑换
「无穷久的性质成立」，这笔兑换的担保人正是数学归纳法本身。

`lth_sound` 里归纳公理的可靠性案例是全章证明的技术高点：给定
□(A→XA) 与 A@k，要证 ∀j≥k A@j——**对距离 j−k 归纳**：

```coq
assert (Hchain : forall d, lsat I (k + d) a).
{ induction d as [| d IHd].
  - rewrite Nat.add_0_r. exact Ha.          (* 基例：d = 0 *)
  - rewrite Nat.add_succ_r.
    apply (Hstep (k + d) (Nat.le_add_r k d) IHd). }   (* 步：保持 *)
replace j with (k + (j - k)) by lia. exact (Hchain (j - k)).
```

这就是「时态归纳 = 自然数归纳」的直接机器证据——36 章语义里
`□` 的 ∀j 量词在这里兑现为归纳法。46 章倒数程序（47 章变体
方法）的归纳不变式，正是这条公理的实例化。

## 可靠性旗舰：lth_sound

```coq
Theorem lth_sound : forall f, lth f -> forall (I : iass) k, lsat I k f.
```

对推导结构归纳，15 个构造子各一行到十行。三个值得停留的案例：

- **Gen□**：定理无假设 ⟹ 对一切起点成立 ⟹ 直接加 ∀j≥k——
  「无上下文」的红利在这里兑现。对照 17 章：带上下文的 Gen
  需要 GenMove 公理与侧条件纠缠，定理式的 Gen 一尘不染。
- **Exp**：第二合取支 X□A 要喂 `Hbox j`（对一切 j≥S k）而非
  `Hbox (S k)`（只给一步）——「永远真」传递给「下一步起永远真」
  要整段区间，机器化时这个量词深度最容易写错（坑位速记）。
- **Lin**：`exact (Hnn Hnx)` 一行——a 与 ¬a 在同一下一步对撞，
  构造性成立（这正是取构造性命题子集的回报：无需排中）。

Lean 通道的镜像版连账单一起打印：`th144_contraction` 零公理、
`lth_sound` 仅 `propext, Quot.sound`（Lean 内核的基础设施，
非逻辑公理）。

## 两条原式推导（Ben-Ari 14.2 / 14.4）

**定理 14.2（X 对 ∧ 分配，前向）** `X(p∧q) → Xp∧Xq`：Ben-Ari
的证明三行——`(p∧q)→p` 经 GenX 得 `X((p∧q)→p)`，DistX 给
`X(p∧q)→Xp`；q 同理；命题组装。机器件逐字复刻：

```coq
assert (H1' : lth (lImp (lNext (lAnd a b)) (lNext a))).
{ apply (lMP _ _ (lDistX (lAnd a b) a)). apply lGenX. apply pAnd1. }
...
exact (lMP _ _ (lMP _ _ (pPair ... H1') H2').
```

**定理 14.4（收缩）** `p ∧ X□p → □p`——不变式方法的演算化身，
Ben-Ari 的五步骨架全部机器化：展开+X 分配得 `r→Xr`（r 即
`p∧X□p`，自身是自己的保持条件）→ Gen 得 `□(r→Xr)` → 归纳
公理给 `r→□r` → 与 `r→p` 复合（□ 单调）。注意第 (1) 步的
巧思：`X□a → X(a∧X□a)` 来自**展开公理的 X-像**——公理的
GenX 提升是推导的常规动作。

这两条定理的语义面（39 章练习可验证）：14.4 在路径上显然
（p 现在真、□p 从下一步起真 ⟹ □p 从现在起真）；推导的价值
在于它**不经过语义**——纯演算地到达同一结论，这正是演算
独立存在的意义（完备性之前的可靠性方向已由 lth_sound 担保）。

## 过去算子与分离定理（§13.6\*，文档级）

Ben-Ari 用带号小节介绍了二值时态算子 U（until）与 S（since，
过去版），以及分离定理：**过去算子不增加表达力**——任何含
过去算子的 LTL 公式等价于「过去部分 ∧ 将来部分」的合取。直觉：
时间是线性的，回望与前瞻各自独立。工程含义：模型检查器不需要
实现过去算子（先翻译成分离形再各自处理）；理论含义：LTL 的
表达力「活在当下与未来」。机器件不做（需要 U/S 语法+语义+
翻译函数的完整工程），登记为边界——41 章的 Büchi 构造同样
只面向将来片段。

## 与全书的接线

- **39 章**：Exp 公理 = 表列 □ 规则的公理化；本章证有效式，
  39 章判可满足——一体两面（可靠+完备把它们缝合，见 22 章）。
- **36 章**：lsat 路径语义（本章的 iass/k 版）与 27 的等价族
  同源；Lin 公理是 36 章「线性」语义条件的公理化回声。
- **17 章**：Gen 的定理式 vs 带上下文式——侧条件消失的两种
  方案（类型吸收 vs 公理记账）。
- **43 章**：Dist 是模态 K 的时态版；□ 是「沿线性序的 □」。
- **46/47/48 章**：归纳公理 = 不变式规则的逻辑内核；48 章将
  把它用在并发程序的每条原子步上。
- **34 章**：L 的可判定证明关系（推导是有穷对象）是算术化
  的前提之一——不完备性证明里「证明可检查」的时态版注脚。

## 本章小结

- 演算的生存空间：无穷/参数化/开放系统的性质推理——枚举
  失效处，推导接手。
- 六公理两规则；命题层取构造性子集（零公理账本）；GenX
  提升为原生规则（Ben-Ari 的导出规则，语义等价）。
- Ind 公理 = 不变式方法的逻辑内核；其可靠性 = 对距离的自然数
  归纳——时态归纳与数学归纳的直通车。
- lth_sound：15 案例归纳；Gen□ 的无上下文红利；Exp 的量词
  深度坑；Lin 的构造性一行证。
- 14.2/14.4 双通道原式推导；过去算子与分离定理登记为边界。

## 坑位速记（本章实测）

- **Coq/Rocq**：
  - **as 模式必须含前提槽位**：`lGen : forall a, lth a -> …`
    的归纳案例槽位是 `a Hp IH`（三槽）——只写 `a IH` 会把
    IH 绑到前提上（19 章同款，第三次出现）；
  - **lsat 的定义展开**：`lsat I k (lNext a)` 与 `lsat I (S k) a`
    定义相等但 apply/specialize 认不出——`simpl in`/`change`/
    `exact`（exact 有 delta）各显神通；`specialize (H (S k) …)`
    对 lNext 型假设是类型错误（它不是函数）；
  - **Exp 的量词深度**：X□A 支要 `change (forall j, S k <= j -> …)`
    后逐 j 喂 `Hbox j`——`Hbox (S k)` 只给一步是常见错；
  - K2 的应用序 `H1 Ha (H2 Ha)`（先吃 a 再吃 b）。
- **Lean**：
  - `def lsat (I) : Nat → Lform → Prop | _, k, .atom p => …`
    的「定义式模式 + 下划线」不被接受——改参数式
    `(k : Nat) (f : Lform) : Prop := match f with`；
  - **theorem 的返回类型必须是 Prop**：归纳谓词先声明成
    `Lform → Type` 会全盘报错（含 `#print axioms` 的对象
    不是命题）；
  - 构造子隐式参数 `{a b}` 与 `_ _` 占位应用冲突——统一显式；
  - 多行项的括号余额机械数（python 逐行 count）——本章一次
    多括号、一次少槽位，都是低级但高频的错。

---

上一章：[39 LTL 语义表列](docs/39-ltltab.md) · 下一章：[41 自动机与 LTL 模型检查](docs/41-buechi.md)
