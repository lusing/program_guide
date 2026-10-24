import Mathlib.SetTheory.Cardinal.Aleph
import Mathlib.Tactic

open scoped Cardinal
open Order

/-!
# 第 74 章 · 基数：和、积与典型秩序（冯琦 §1.9）

mathlib 官方锚点：`Cardinal.add_eq_max`/`Cardinal.mul_eq_max`
（推论 1.13：κ+λ = κ·λ = max{κ,λ} 的官方形态）、
`Cardinal.aleph` 序列与 `Cardinal.succ_aleph`（定义 1.93）、
`Cardinal.aleph_strictMono`（定理 1.91(1)）。
Gödel 编码与"方块=前段"由 Julia/Python/Prolog/Coq/Agda 五通道承载
（Coq 通道给出 ℕ 截面双射的完整证明）。
-/

namespace Settheory.Ch74

-- ---------- 推论 1.13：无穷基数的和积坍缩到 max ----------

/-- 和的官方形态：ℵ₀ ≤ a → a + b = max a b。 -/
theorem add_eq_max_official (a b : Cardinal) (ha : ℵ₀ ≤ a) : a + b = max a b :=
  Cardinal.add_eq_max ha

/-- 积的官方形态（两变元皆无穷）。 -/
theorem mul_eq_max_official (a b : Cardinal) (ha : ℵ₀ ≤ a) (hb : ℵ₀ ≤ b) :
    a * b = max a b :=
  Cardinal.mul_eq_max ha hb

/-- 最早两例：ℵ₀+ℵ₀ = ℵ₀、ℵ₀·ℵ₀ = ℵ₀（69 章 |ω×ω| = |ω| 的官方化）。 -/
theorem aleph0_add_self : ℵ₀ + ℵ₀ = ℵ₀ := by
  rw [Cardinal.add_eq_max le_rfl, max_self]

theorem aleph0_mul_self : ℵ₀ * ℵ₀ = ℵ₀ := by
  rw [Cardinal.mul_eq_max le_rfl le_rfl, max_self]

-- ---------- 定义 1.93：ℵ 序列 ----------

/-- ℵ_0 = ℵ₀：序列从 ω 起步。 -/
example : ℵ_ 0 = ℵ₀ := Cardinal.aleph_zero

/-- 后继步：succ(ℵ_α) = ℵ_{α+1}（α⁺ 的官方版）。 -/
example (o : Ordinal) : Order.succ (ℵ_ o) = ℵ_ (o + 1) := Cardinal.succ_aleph o

/-- 严格递增（定理 1.91(1) 的 iff 官方版）。 -/
example : StrictMono Cardinal.aleph := fun _ _ h => Cardinal.aleph_lt_aleph.2 h

/-- ℵ 序列的每一项都是无穷基数（定理 1.90 前半）。 -/
example (o : Ordinal) : ℵ₀ ≤ ℵ_ o := Cardinal.aleph0_le_aleph o

end Settheory.Ch74
