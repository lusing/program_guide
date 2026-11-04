import Mathlib.Tactic

/-!
# 第 133 章 序数与超穷归纳（Lean）

序数类型、定理 4.2.10 的 mathlib 形态（`Ordinal.type`）、超穷归纳
原理（`Ordinal.induction`）、序数的良序（4.2.8(d)）与
"自然数恰是有穷序数"（4.2.9）。
-/

/-! ## 序数类型与序型 -/

#check @Ordinal.type
/- `Ordinal.type r`：良序 r 的序型——定理 4.2.10"每个良序集同构于
唯一序数"在 mathlib 中是 type 的定义性存在；`typein` 给出元素到
其前段的映射（同构的显式形态）。 -/
#check @Ordinal.typein

/-! ## 超穷归纳原理（书 4.3.1） -/

#check @WellFoundedLT.induction

/-- 超穷归纳（书 4.3.1）：注意 4.33 里推荐用 WellFoundedLT.induction。 -/
example (p : Ordinal → Prop) (h : ∀ α, (∀ β < α, p β) → p α) : ∀ α, p α :=
  fun α => WellFoundedLT.induction α h

/-! ## 序数的良序（书 4.2.8(d)） -/

example : IsWellOrder Ordinal (· < ·) := inferInstance

#check @Ordinal.lt_wf

/-! ## 自然数恰是有穷序数（书 4.2.9） -/

#check @Ordinal.natCast_lt_omega0

example (n : ℕ) : (n : Ordinal) < Ordinal.omega0 := by
  exact Ordinal.natCast_lt_omega0 n

/-! ## ω 的算术预告（第 134 章展开） -/

/-- 1 + ω = ω（书例 4.4.2(4)）。 -/
example : (1 : Ordinal) + Ordinal.omega0 = Ordinal.omega0 :=
  Ordinal.one_add_omega0

/-- 但 ω + 1 > ω——加法不交换的第一个见证。 -/
example : Ordinal.omega0 < Ordinal.omega0 + 1 := by simp
