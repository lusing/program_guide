import Mathlib.Tactic
import Mathlib.NumberTheory.Real.Irrational

/-!
# 第 07 章 整数、有理数、实数（Lean）

ℚ 缺陷的可判定账目（书 3.5.2 的魔法公式在两个方向上都是多项式
恒等式，机器直接收割）、ℝ 的最小上界性质（书 3.5.6）、√2 的
无理性、稠密性的 instance 形态。
-/

/-! ## ℚ 的缺陷：A 无最大元、B 无最小元（书 3.5.2） -/

/-- 书 (3.17) 的魔法公式：q = p − (p²−2)/(p+2)。
方向一：p ∈ A（0 < p 且 p² < 2）⟹ 存在更大的 q 仍在 A。 -/
example (p : ℚ) (hp : 0 < p) (h : p * p < 2) :
    ∃ q : ℚ, p < q ∧ q * q < 2 := by
  refine ⟨p - (p * p - 2) / (p + 2), ?_, ?_⟩ <;>
    [skip; skip]
  · field_simp
    nlinarith
  · field_simp
    nlinarith

/-- 方向二：p ∈ B（p² > 2）⟹ 存在更小的 q 仍在 B——
同一公式反着用。 -/
example (p : ℚ) (hp : 0 < p) (h : 2 < p * p) :
    ∃ q : ℚ, q < p ∧ 2 < q * q := by
  refine ⟨p - (p * p - 2) / (p + 2), ?_, ?_⟩ <;>
    [skip; skip]
  · field_simp
    nlinarith
  · field_simp
    nlinarith

/- 于是 A = {p | p² < 2} 在 ℚ 中有上界而无上确界：
上确界若在 A 内则 A 有最大元（矛盾），若在 ℚ\A 内则 B 有最小元
（矛盾）。ℚ 没有最小上界性质。 -/

/-! ## ℝ 的最小上界性质（书 3.5.6） -/

#check @Real.exists_isLUB

example : ∃ x, IsLUB {r : ℝ | r * r < 2} x := by
  apply Real.exists_isLUB ⟨1, by norm_num⟩
  refine ⟨2, ?_⟩
  rintro r hr
  rcases lt_or_ge r 2 with h | h
  · exact le_of_lt h
  · -- r ≥ 2 时 r² ≥ 4 > 2，与 hr 矛盾
    have h1 : 0 ≤ r - 2 := by linarith
    have h2 : 0 ≤ (r - 2) * (r - 2) := mul_nonneg h1 h1
    have key : 4 ≤ r * r := by nlinarith [h2]
    exact absurd hr (not_lt.mpr ((by norm_num : (2:ℝ) ≤ 4).trans key))

/-- 上确界正是 √2——而它不是有理数。 -/
theorem sqrt_two_not_rational : Irrational (Real.sqrt 2) :=
  irrational_sqrt_two

/-! ## 稠密性与嵌入链 -/

/-- ℚ 与 ℝ 都是稠密线序（书 3.4.14 与 3.5 节末）——instance 形态。 -/
example : DenselyOrdered ℚ := inferInstance

example : DenselyOrdered ℝ := inferInstance

/-- 嵌入链 ℕ ⊂ ℤ ⊂ ℚ ⊂ ℝ 保运算（书 3.4.6/3.4.11/3.5.10）。 -/
example (m n : ℕ) : ((m + n : ℕ) : ℝ) = (m : ℝ) + (n : ℝ) := by
  push_cast
  ring
