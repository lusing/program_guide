# 17 · 组合数学

> 对应示例：`examples/14_mathlib_combinatorics/combinatorics.lean`

源码坐标：`Mathlib/Data/Finset/Basic.lean`（Finset）、`Mathlib/Algebra/BigOperators/Group/Finset/Defs.lean`（∑ ∏ 记号）、`Mathlib/Data/Nat/Choose/Basic.lean`（二项式系数）、`Mathlib/Data/Fintype/Pigeonhole.lean`（鸽笼原理）。

## 17.1 Finset：带证明的有限集合

`Finset α`（`Mathlib/Data/Finset/Basic.lean`）= `Multiset α` + 无重复证明。与 `Set α` 的本质区别：Finset **可计算、可枚举**，Set 是任意谓词。

```lean
import Mathlib.Data.Finset.Basic

-- 字面量与基本操作（Finset 默认无 Repr，#eval 演示走 card/∈）
#eval ({1, 2, 3} : Finset ℕ).card          -- 3
#eval 3 ∈ ({1, 2, 3} : Finset ℕ)           -- true（Decidable）
#eval (({1, 2, 3} : Finset ℕ) ∪ {3, 4}).card   -- 4
#eval (({1, 2, 3} : Finset ℕ) ∩ {2, 3}).card   -- 2
#eval (Finset.range 5).card                -- 5

-- card 的基本引理
example (s t : Finset ℕ) (h : s ⊆ t) : s.card ≤ t.card := Finset.card_le_card h
example (s : Finset ℕ) : s.card = 0 ↔ s = ∅ := Finset.card_eq_zero
```

**Finset vs Set 的选择**：需要 `∑`、归纳、`decide` 时用 Finset；需要连续性/测度语境时用 Set。互转：`s.toSet`、`Set.Finite.toFinset`。

## 17.2 大算子：∑ 与 ∏（2026 新记号）

**记号变更提醒**：2026 版 mathlib 的大算子绑定符用 `∈`（不再用 `in`），定义在 `Mathlib/Algebra/BigOperators/Group/Finset/Defs.lean:181`：

```lean
import Mathlib.Algebra.BigOperators.Group.Finset.Defs
import Mathlib.Algebra.BigOperators.Intervals

open Finset    -- range 等

-- 基本形态
#eval ∑ i ∈ range 10, i            -- 45
#eval ∑ i ∈ range 5, (i : ℚ)^2     -- 30（ℝ 不可计算——柯西商，数值演示用 ℚ）
#eval ∏ i ∈ range 5, (i + 1 : ℕ)   -- 120

-- 高级绑定形式（Defs 注释里的完整菜单）：
-- ∑ x ∈ s with p x, f x        ← 带过滤
-- ∑ (x ∈ s) (y ∈ t), f x y     ← 笛卡尔积
-- ∑ ⟨x, y⟩ ∈ s ×ˢ t, f x y     ← 解构模式
example : ∑ p ∈ (range 3) ×ˢ (range 3), p.1 * p.2 = 9 := by decide

-- 高斯求和（Intervals.lean:181）
example (n : ℕ) : ∑ i ∈ range n, i = n * (n - 1) / 2 := Finset.sum_range_id n

-- 求和的核心代数引理（命名规律 sum_op / op_sum）
example (s : Finset ι) (f g : ι → ℝ) :
    ∑ i ∈ s, (f i + g i) = ∑ i ∈ s, f i + ∑ i ∈ s, g i := Finset.sum_add_distrib
-- Finset.mul_sum 的方向是"提出因子" a * ∑ f = ∑ a * f，取 .symm 得左展开
example (s : Finset ι) (c : ℝ) (f : ι → ℝ) :
    ∑ i ∈ s, c * f i = c * ∑ i ∈ s, f i := (Finset.mul_sum s f c).symm
```

## 17.3 二项式系数与二项式定理

```lean
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Data.Nat.Choose.Sum

-- Nat.choose（Choose/Basic.lean）
#eval Nat.choose 5 2     -- 10
example (n : ℕ) : Nat.choose n 0 = 1 := Nat.choose_zero_right n
example (n : ℕ) : Nat.choose n n = 1 := Nat.choose_self n

-- 帕斯卡恒等式
example (n k : ℕ) : Nat.choose (n + 1) (k + 1) = Nat.choose n k + Nat.choose n (k + 1) :=
  Nat.choose_succ_succ n k

-- 二项式定理（Choose/Sum.lean:76）——注意项的排列与类型提升
example (a b : ℝ) (n : ℕ) :
    (a + b) ^ n = ∑ k ∈ Finset.range (n + 1), a ^ k * b ^ (n - k) * n.choose k :=
  add_pow a b n

-- 推论：Σ C(n,k) = 2^n（Choose/Sum.lean:94）
example (n : ℕ) : ∑ k ∈ Finset.range (n + 1), n.choose k = 2 ^ n :=
  Nat.sum_range_choose n
```

## 17.4 鸽笼原理

源码：`Mathlib/Data/Fintype/Pigeonhole.lean:46`（注意 2026 起在 Data/Fintype 下，不在 Combinatorics 目录）：

```lean
import Mathlib.Data.Fintype.Pigeonhole

-- Fintype 版：|β| < |α| 则 α→β 无单射
example [Fintype α] [Fintype β] (f : α → β)
    (h : Fintype.card β < Fintype.card α) :
    ∃ x y : α, x ≠ y ∧ f x = f y :=
  Fintype.exists_ne_map_eq_of_card_lt f h

-- Finset 版（Data/Finset/Card.lean:470）：带值域限制
example {s : Finset α} {t : Finset β} {f : α → β}
    (hc : t.card < s.card) (hf : ∀ a ∈ s, f a ∈ t) :
    ∃ x ∈ s, ∃ y ∈ s, x ≠ y ∧ f x = f y :=
  Finset.exists_ne_map_eq_of_card_lt_of_maps_to hc hf

-- 实战练习：n+1 个 [0, 2n) 中的数必有两个同余 mod n
example (n : ℕ) (a : Fin (n + 1) → Fin n) :
    ∃ i j : Fin (n + 1), i ≠ j ∧ a i = a j :=
  Fintype.exists_ne_map_eq_of_card_lt a (by simp)
```

---

> 上一章：[16 · 线性代数](16-linear-algebra.md) ｜ 下一章：[18 · 测度论与概率论](18-measure-probability.md) ｜ 返回：[README](../README.md)
