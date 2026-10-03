# 18 前束范式：量词穿越的等价保持

> 对书：Mendelson §2.10 / EFT VIII.4 / Ben-Ari 3e §9.2

前束范式（PNF）= 全部量词提到最前面的等价形式。完整算法
（变元标准化 + 量词逐层前移 + ¬/→ 的经典改写）是大工程——
本章机器化它的**循环不变式核心**：量词穿越 ∧/∨ 的等价。

## 旗舰四条（全部零公理）

```
all_and_split  ∀x.(P∧Q) → (∀x.P ∧ ∀x.Q)         分配
all_or_mono    (∀x.P) → ∀x.(P∨Q)                  单调
all_and_join   (∀x.P) ∧ Q → ∀x.(P∧Q)（x∉FV Q）   穿越合取
all_or_swap    (∀x.P) ∨ Q → ∀x.(P∨Q)（x∉FV Q）   穿越析取
```

**侧条件的不对称**是教学重点：`all_and_join`/`all_or_swap` 的
条件只在 **Q 侧**（P 被量词管住不需要条件）——若 x ∈ FV(Q)，
穿越会**捕获** Q 的自由变元（`∀x.(P(x)∧Q(x))` 与
`(∀x.P(x))∧Q(x)` 在 x 处语义不同）。

## 侧条件的引擎：一致性 + 无关性

```
peval_coincidence   赋值在 FV 上一致 → 语义 iff（15 章配方复用）
peval_irrelevant_at x ∉ FV(f) → 换 x 处赋值不改变语义
```

`irrelevant_at` 是 `coincidence` 的直接推论：`e` 与
`eupdb e x v` 只在 x 处不同，而 x ∉ FV(f)。

## 论域设计

布尔论域（`∀ v : bool`）——避免 nat 无穷量化的语义复杂度，
量词穿越的等价结构完全保留。二元下的 `eupdb` 就是 15 章
`eupd` 的 bool 特化。

## 坑位速记（本章实测）

- **Coq**：
  - `keep_remove` 的 `In z (a::l)` 等式是 `a = z`（头=元素）——
    与 `Heq : y = a` 的链条方向 `eq_trans (eq_sym Heq') (eq_sym Heq)`；
  - `right` 对 `In z (remove …)` 报 not inductive——remove 后
    In 是 fixpoint 应用，需分支内再 `simpl`；y=a 分支 remove
    直接变 `l'`（不是 cons）——直接 `apply IH` 不带 `right`；
  - `peval_irrelevant_at` 的 iff 方向：e → eupdb 是 `.mp`
    （all_and_join 用的是从 e 到 eupdb 的正向）；
  - `pull_one` 的侧条件 `[H|H]`——`discriminate H` 对
    `1 = 2` 有效但 `In 1 []` 要 `contradiction`。
- **Lean**：
  - `patom` 的语义 `pe p x = true` 与赋值 **e 无关**（谓词
    作用于变元号本身）——一致性引理的 patom 分支是
    `simp only [peval]` 后直接 rfl，无需 h；
  - `peval` 必须返回 `Prop`（`= true`），裸 `pe p x` 是 Bool；
  - `(m == y) = false` 的建立走 `cases hb : (m == y)` +
    `simpa using hb`（`Nat.eq_of_beq_eq` 在独立 Lean 不存在）；
  - iff 的所有分支 `.mp/.mpr`（17 章坑复现）。
