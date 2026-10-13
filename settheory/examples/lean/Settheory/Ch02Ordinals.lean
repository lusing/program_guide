import Mathlib.SetTheory.Ordinal.Arithmetic
import Mathlib.Order.Basic

open scoped Ordinal

/-!
# 第 02 章 · 序数与超穷归纳递归

mathlib 的 `Ordinal` 理论覆盖 Jech §2 的全部主线：三歧性、
超穷归纳、序数算术。本章机器化其中最核心的锚点。
-/

/-! ## 一、三歧性与超穷归纳 -/

/-- 序数 < 的三歧性（Jech (2.1)）：任何两序数可比。 -/
example (a b : Ordinal) : a < b ∨ a = b ∨ b < a :=
  lt_trichotomy a b

/-- **超穷归纳**（Jech 定理 3）：若每个序数从"所有更小者满足 P"
   能推出自己满足 P，则所有序数满足 P。 -/
theorem transfinite_induction_demo (P : Ordinal → Prop)
    (h : ∀ j, (∀ k, k < j → P k) → P j) : ∀ i, P i :=
  fun i => WellFoundedLT.induction i h

/-! ## 二、ω 与有限序数 -/

/-- 有限序数就是自然数；ω 在它们全部之后。 -/
example (n : ℕ) : (n : Ordinal) < ω := Ordinal.natCast_lt_omega0 n

/-- 吸收律：有限 + ω = ω（加法不可交换的著名不等式一侧）。 -/
example (n : ℕ) : (n : Ordinal) + ω = ω := Ordinal.natCast_add_omega0 n

example : (1 : Ordinal) + ω = ω := Ordinal.one_add_omega0

/-- 反方向不塌缩：ω + 1 是 ω 的后继，严格更大。
    ω 不是极大元（后面还有 ω+1 等），用 lt_succ_iff_not_isMax。 -/
example : ω < ω + 1 := by
  rw [← Order.succ_eq_add_one]
  exact Order.lt_succ_iff.2 le_rfl

/-! ## 三、序数算术的结合律（无交换律） -/

/-- 加法结合律（Jech §2）：(α+β)+γ = α+(β+γ)。 -/
example (a b c : Ordinal) : (a + b) + c = a + (b + c) :=
  add_assoc a b c

/-- 左分配律 α·(β+γ) = α·β + α·γ（注意反向不成立）。 -/
example (a b c : Ordinal) : a * (b + c) = a * b + a * c :=
  mul_add a b c
