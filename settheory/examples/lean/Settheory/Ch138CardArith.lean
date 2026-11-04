import Mathlib.Tactic

/-!
# 第 138 章 基数算术（Lean）

无穷基数的吸收律：κ + κ = κ、κ · κ = κ（书 5.2.5）与
κ ⊞ λ = κ ⊙ λ = max(κ,λ)（书 5.2.6）——全部是 mathlib 库定理。
-/

/-! ## 吸收律（书 5.2.5 定理与推论 5.2.6） -/

/-- κ + κ = κ 对一切无穷 κ（希尔伯特旅馆的算术形式）。 -/
example (κ : Cardinal) (h : Cardinal.aleph0 ≤ κ) : κ + κ = κ :=
  Cardinal.add_eq_self h

/-- κ · κ = κ 对一切无穷 κ——书 5.2.5 的标准序证明（按 max 分层，
逐层计数）在 mathlib 里的成品。 -/
example (κ : Cardinal) (h : Cardinal.aleph0 ≤ κ) : κ * κ = κ :=
  Cardinal.mul_eq_self h

/-- 推论 5.2.6：两个无穷基数的和与积都等于较大者。 -/
example (κ μ : Cardinal) (hκ : Cardinal.aleph0 ≤ κ) :
    κ + μ = max κ μ :=
  Cardinal.add_eq_max hκ

example (κ μ : Cardinal) (hκ : Cardinal.aleph0 ≤ κ) (hμ : Cardinal.aleph0 ≤ μ) :
    κ * μ = max κ μ :=
  Cardinal.mul_eq_max hκ hμ

/-! ## 有限情形的对照 -/

/-- 有限基数回到普通算术：3 + 3 = 6 ≠ 3——吸收律是无穷的专利。 -/
example : ((3 : Cardinal) + 3 = 6) := by norm_num

example : ((3 : Cardinal) * 3 = 9) := by norm_num

/-! ## 幂的哨兵：Cantor 梯的起点 -/

#check @Cardinal.cantor

/- κ < 2^κ：幂运算总是"往上走"——对 κ = ℵ₀ 给出 c = 2^{ℵ₀} > ℵ₀
（实数的基数）；连续统假设问的正是 c 是否 = ℵ₁（第 140 章展开）。 -/

example : Cardinal.aleph0 < 2 ^ Cardinal.aleph0 := Cardinal.cantor _
