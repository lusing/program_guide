/-
文件: 14_mathlib_combinatorics/pigeonhole.lean
描述: 鸽巢原理
编译: lake build Lean4Tutorial.Examples.MathlibCombinatorics.Pigeonhole
依赖: Mathlib.Data.Finset.Pigeonhole
-/

import Mathlib.Data.Finset.Pigeonhole
import Mathlib.Data.Finset.Basic

namespace Lean4Tutorial.Examples.MathlibCombinatorics.Pigeonhole

/-! # 鸽巢原理（Pigeonhole Principle） -/

-- 鸽巢原理：如果 n 只鸽子飞入 m 个鸽巢，且 n > m，
-- 则至少有一个鸽巢中有至少两只鸽子
--
-- 数学表述：如果 f : A → B 且 |A| > |B|，则 f 不是单射
-- 即存在 a₁ ≠ a₂ 使得 f(a₁) = f(a₂)

/-! ## 有限集合上的鸽巢原理 -/

-- Mathlib 中的鸽巢原理
#check Finset.exists_ne_map_eq_of_card_lt_of_maps_to

-- 如果 s.card > t.card，且 f 将 s 映入 t，
-- 则存在两个不同的元素映射到同一个值
theorem pigeonhole_principle {α β : Type*} [DecidableEq β]
    (s : Finset α) (t : Finset β) (f : α → β)
    (h1 : s.card > t.card) (h2 : ∀ x ∈ s, f x ∈ t) :
    ∃ x y, x ∈ s ∧ y ∈ s ∧ x ≠ y ∧ f x = f y := by
  exact?

/-! ## 鸽巢原理的例子 -/

-- 例 1：在任意 13 个人中，至少有两个人的生日在同一个月
-- （12 个月，13 个人 → 至少一个月有 2 人）

theorem birthday_month :
    ∀ (f : Fin 13 → Fin 12),
    ∃ (i j : Fin 13), i ≠ j ∧ f i = f j := by
  intro f
  exact?

-- 例 2：在任意 n + 1 个整数中，必有两个数模 n 同余
-- （模 n 有 n 个剩余类，n + 1 个数 → 至少两个在同一类）

theorem mod_pigeonhole (n : ℕ) (hn : n > 0)
    (a : Fin (n + 1) → ℕ) :
    ∃ (i j : Fin (n + 1)), i ≠ j ∧ a i % n = a j % n := by
  exact?

/-! ## 鸽巢原理的推广 -/

-- 如果 kn + 1 只鸽子飞入 n 个鸽巢，
-- 则至少有一个鸽巢中有至少 k + 1 只鸽子

-- 一般形式：
-- 如果 f : A → B，则存在 b ∈ B 使得
-- |f⁻¹(b)| ≥ |A| / |B|

-- 即至少有一个鸽巢中的鸽子数不少于平均值

/-! ## 狄利克雷逼近定理 -/

-- 鸽巢原理的一个著名应用是狄利克雷逼近定理：
-- 对于任意实数 α 和正整数 n，存在整数 p, q，
-- 使得 1 ≤ q ≤ n 且 |α - p/q| < 1/(nq)

-- 这说明任何实数都可以被有理数很好地逼近

/-! ## 拉姆齐理论简介 -/

-- 拉姆齐理论是鸽巢原理的推广
-- 研究的是：在多大的集合中，必然存在某种结构

-- 拉姆齐数 R(s, t) 是最小的 n，使得
-- 任何 n 个顶点的图，要么包含 s 个顶点的完全子图，
-- 要么包含 t 个顶点的独立集

-- 已知的拉姆齐数：
--   R(3, 3) = 6
--   R(3, 4) = 9
--   R(3, 5) = 14
--   R(4, 4) = 18
--   R(5, 5) 未知（介于 43 和 48 之间）

/-! ## 鸽巢原理的其他应用 -/

-- 1. 中国剩余定理的存在性证明
-- 2. 图论中的各种存在性证明
-- 3. 数论中的丢番图逼近
-- 4. 计算机科学中的哈希冲突分析

/-! ## 无限版本的鸽巢原理 -/

-- 对于无限集合：
-- 如果 A 是无限集，B 是有限集，f : A → B，
-- 则存在 b ∈ B 使得 f⁻¹(b) 是无限集

-- 即无限多只鸽子飞入有限个鸽巢，
-- 至少有一个鸽巢中有无限多只鸽子

end Lean4Tutorial.Examples.MathlibCombinatorics.Pigeonhole
