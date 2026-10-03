# 17 FOL Hilbert 系统：Gen 侧条件的演绎定理

> 对书：Mendelson §2.3-2.6 / Ben-Ari 3e Ch8.2

05 章命题 Hilbert 的 FOL 扩展：命题 K/S 公理 + 量词公理 + Gen 规则。

## 公理系统（深嵌入）

```
K1  P → (Q → P)
K2  (P→(Q→R)) → ((P→Q)→(P→R))
K5  ∀x.Pt → Pt[x:=t]        （量词消去）
K6  ∀x.(P→Q) → (∀x.P → ∀x.Q)  （量词分配）
Gen 从 A 得 ∀x.A

GenMove（带侧条件的公理模式）：
    x ∉ FV(P) ⟹ ∀x.(P→Q) → (P→∀x.Q)
    （「Gen 后移」——Enderton 式通用实例公理）
```

## 旗舰：演绎定理的 Gen 侧条件版（Coq 完整 / Lean 单假设版）

```
fdeduction_closed : closedF A → fder (A :: G) B → fder G (A → B)
```

四分支：假设（K1 装配）、公理（K1 装配）、MP（K2 装配）、
**Gen（GenMove 装配）**——Gen 分支的侧条件由 `closedF A` 担保：
对任意 x，x ∉ FV(A)（闭公式无自由变元）。

**Gen 侧条件不可省的经典反例**（文档）：A := P(x) 时
A ⊢ ∀x.A（Gen 合法）但 ⊬ A→∀x.A——演绎定理对含自由变元的
假设失效。这正是 Mendelson 定理 2.4（演绎定理）需要
「Gen 不作用于 A 的自由变元」限制的原因。

## 带侧条件的公理模式（深嵌入的处理）

GenMove 的侧条件 `x ∉ FV(P)` 是**可判定的语义条件**——
深嵌入中作为公理构造子的 Prop 前提合法：
Lean 版 `gen_move (x P Q) (h : x ∉ fFV P) : IsAx …`。
这与「公理模式 = 纯语法形状」的传统观念的边界被诚实登记。

## Lean 版的完整边界实录（本章坑位之王）

Lean 版走**单假设环境（A :: G）**路线，其中踩出三个连环坑：

1. **FDer 的环境若做「参数」**——induction 的 IH 不携带环境
   （fweak 无法归纳）；做**双索引**后构造子字段的 G 又被
   induction 自动 unify、with 子句绑定数对不上；
2. **环境是封闭值 [A] 时**——induction 无法泛化索引（IH 固定
   A::G）——必须 A :: G（G 变量）才能泛化；
3. **with 子句的绑定顺序**——@fMP P B h1 **h2** ih1 **ih2**
   （字段全部在前、IH 在后）——写 h1 ih1 h2 ih2 会错位绑定
   （ih1 绑到 h2 的位置，报「Function expected」）。

G 版的完整演绎定理（含 weaken）在 Coq 通道；Lean 版边界如实记录。

## 坑位速记（本章实测）

- **Coq**：`/\\` 在 Python 字符串中被吃掉（K6 公理的合取符号
  变成 `/ + 空格`）；fFV 定义必须在 isAx 之前（公理引用它）；
  `right; right; right; right` 的析取层数=公理模式序号；
  `rewrite Hcl. intros Hc. destruct Hc.` 处理 `x ∈ []`。
- **Lean**：见上节三连坑；另有 fAx 的 A 字段显式
  （调用要 `fAx _ hax`）；`simp [List.not_mem_nil]` 在
  `hnil : B0 ∈ []` 上无 progress（直接 cases）。
