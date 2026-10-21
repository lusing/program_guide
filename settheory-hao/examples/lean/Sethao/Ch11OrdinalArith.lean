import Mathlib.Tactic

/-!
# 第 11 章 超穷递归与序数算术（Lean）

序数算术的结合律、左消去律（书 4.4.4）、ω 吸收律的非交换性现场，
以及超穷递归定理（书 4.3.5）的 mathlib 形态。
-/

/-! ## 加法的合法性与消去律 -/

/-- 加法结合律（对序数成立，如书 4.4 的全部推导所默认）。 -/
example (a b c : Ordinal) : a + b + c = a + (b + c) := by ac_rfl

/-- 乘法结合律。 -/
example (a b c : Ordinal) : a * b * c = a * (b * c) := by ac_rfl

/- 左严格单调（书 4.4.4(1)：β+α₁ < β+α₂ ⟺ α₁ < α₂）——通过
Covariant 实例走根命名空间的 add_lt_add_iff_left。 -/
example (β α₁ α₂ : Ordinal) (h : α₁ < α₂) : β + α₁ < β + α₂ :=
  (add_lt_add_iff_left β).mpr h

/-! ## ω 吸收律：非交换性现场（书例 4.4.2） -/

/- m + ω = ω 对一切自然数 m（Ordinal.add_omega0）。 -/

example (m : ℕ) : (m : Ordinal) + Ordinal.omega0 = Ordinal.omega0 :=
  Ordinal.add_omega0 (Ordinal.natCast_lt_omega0 m)

/-- 1 + ω = ω。 -/
example : (1 : Ordinal) + Ordinal.omega0 = Ordinal.omega0 :=
  Ordinal.one_add_omega0

/-- 但 ω + 1 > ω：加法不交换。 -/
example : Ordinal.omega0 + (1 : Ordinal) ≠ (1 : Ordinal) + Ordinal.omega0 := by
  simp

/-! ## 超穷递归定理（书 4.3.5） -/

/- mathlib 的 `Ordinal.limitRecOn` 打包了超穷递归的三段式
（零/后继/极限——书 (4.10) 的 G₁/G₂/G₃）。 -/
#check @Ordinal.limitRecOn
