import Mathlib.Tactic

/-!
# 第 17 章 联合、边际与条件分布（Lean）

有限联合表的精确账：3×3 联合 pmf（行 X、列 Y）的归一、两个边际
（均为 1/3）、条件分布归一、乘积检验失败（1/6 ≠ 1/9），以及一般
情形的两个代数事实：独立 ⇒ 因子分解（联合 = 边际积）与条件
概率归一。全部为 ℚ 上的 `norm_num` / `ring` / `field_simp`，无 sorry。
-/

/-! ## 具体联合表 -/

/-- 联合 pmf 表（行 X=0,1,2；列 Y=0,1,2）。 -/
def jt : Fin 3 → Fin 3 → ℚ :=
  ![![1/12, 1/12, 1/6], ![1/12, 1/6, 1/12], ![1/6, 1/12, 1/12]]

/-- **归一**：九格之和为 1。 -/
example : ∑ x : Fin 3, ∑ y : Fin 3, jt x y = 1 := by
  simp [jt, Fin.sum_univ_three]; norm_num

/-- **边际 X**：每一行之和都是 1/3。 -/
example : ∀ x : Fin 3, ∑ y : Fin 3, jt x y = 1 / 3 := by
  intro x; fin_cases x <;> simp [jt, Fin.sum_univ_three] <;> norm_num

/-- **边际 Y**：每一列之和都是 1/3。 -/
example : ∀ y : Fin 3, ∑ x : Fin 3, jt x y = 1 / 3 := by
  intro y; fin_cases y <;> simp [jt, Fin.sum_univ_three] <;> norm_num

/-- **条件分布**：P(Y=2 | X=0) = (1/6)/(1/3) = 1/2。 -/
example : jt 0 2 / (∑ y : Fin 3, jt 0 y) = 1 / 2 := by
  simp [jt, Fin.sum_univ_three]; norm_num

/-- **条件分布归一**：对 X=1，Σ_y p(y|1) = 1。 -/
example : ∑ y : Fin 3, jt 1 y / (∑ y' : Fin 3, jt 1 y') = 1 := by
  simp [jt, Fin.sum_univ_three]; norm_num

/-- **不独立**：边际积 (1/3)(1/3) = 1/9，而联合格 p(0,2) = 1/6。 -/
example : jt 0 2 ≠ (1 / 3) * (1 / 3) := by
  simp [jt]; norm_num

/-! ## 一般代数事实 -/

/-- **乘积表独立**：若联合 = a·b（a、b 为边际），则 p(y|x) = b(y)，
条件分布不依赖 x。 -/
example (a b : ℚ) (ha : a ≠ 0) : (a * b) / a = b := by
  field_simp

/-- **全概率**：两分区的混合边际，f = (1−π)f₀ + πf₁ 的后验
P(Z=1|y) = πf₁/f，且与 P(Z=0|y) 之和为 1。 -/
example (π f₀ f₁ : ℚ) (h : (1 - π) * f₀ + π * f₁ ≠ 0) :
    π * f₁ / ((1 - π) * f₀ + π * f₁)
      + (1 - π) * f₀ / ((1 - π) * f₀ + π * f₁) = 1 := by
  field_simp
  ring

/-- **二元指数**：P(X<Y) = λ/(λ+μ)，两侧互补相加为 1。 -/
example (l m : ℚ) (hl : 0 < l) (hm : 0 < m) :
    l / (l + m) + m / (l + m) = 1 := by
  have : l + m ≠ 0 := by positivity
  field_simp

/-- **多项分布 n=2 的归一**：(p₁+p₂+p₃)² 展开为六个格点概率之和。 -/
example (a b c : ℚ) :
    (a + b + c) ^ 2 = a ^ 2 + b ^ 2 + c ^ 2 + 2 * a * b + 2 * a * c + 2 * b * c := by
  ring
