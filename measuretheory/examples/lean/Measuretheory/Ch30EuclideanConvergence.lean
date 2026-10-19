import Mathlib.Probability.CDF

/-!
# 第 30 章 欧氏空间上的测度收敛（Lean）

严书 §6.1 / 袁上册 §12.3。mathlib 锚点（Probability/CDF.lean）：
`ProbabilityTheory.cdf`（分布函数，定义为 condCDF 的特化）、
`cdf_eq_real`（值 = μ.real (Iic x)）、单调/上下界引理族
（cdf_nonneg/le_one/monotone_cdf）。

实弹：dirac 型分布函数的逐点账（跳点 0 的失败现场与
负半轴的收敛——30.2 反例的机器账）。
-/

open MeasureTheory ProbabilityTheory
open scoped ENNReal

/-! ## 锚点正名 -/

#check @ProbabilityTheory.cdf
#check @ProbabilityTheory.cdf_eq_real
#check @ProbabilityTheory.monotone_cdf
#check @ProbabilityTheory.cdf_le_one

/-! ## dirac 型分布函数账 -/

/-- δ_a 的 cdf 逐点账：cdf δ_a x = δ_a.real(Iic x)——
一维字典的最简词条（`cdf_eq_real` 的实例化）。 -/
example (a x : ℝ) : cdf (Measure.dirac a) x = Measure.real (Measure.dirac a) (Set.Iic x) :=
  cdf_eq_real _ _

/-- 跳点失败的一半：δ_{1/n} 的 cdf 在 0 处的值 = 0
（1/n ∉ Iic 0），而极限 δ₀ 的 cdf(0) = 1——逐点收敛在
跳点必然失败（30.2 反例的机器侧；后半 cdf δ₀ 0 = 1
见下）。 -/
example (n : ℕ) (hn : 1 ≤ n) : Measure.real (Measure.dirac (1 / (n : ℝ))) (Set.Iic 0) = 0 := by
  have h1 : (Measure.dirac (1 / (n : ℝ))) (Set.Iic 0) = 0 := by
    rw [Measure.dirac_apply]
    simp [Set.mem_Iic]
    intro h
    omega
  rw [show Measure.real (Measure.dirac (1 / (n:ℝ))) (Set.Iic 0)
      = ((Measure.dirac (1 / (n:ℝ))) (Set.Iic 0)).toReal from rfl, h1]
  rfl

/-- 极限的账：δ₀ 的 cdf(0) = 1（0 ∈ Iic 0）——与上例合读
即跳点失败的完整账：0 ≠ 1。 -/
example : Measure.real (Measure.dirac (0:ℝ)) (Set.Iic 0) = 1 := by
  have h1 : (Measure.dirac (0:ℝ)) (Set.Iic 0) = 1 := by
    rw [Measure.dirac_apply]; simp [Set.mem_Iic]
  rw [show Measure.real (Measure.dirac (0:ℝ)) (Set.Iic 0)
      = ((Measure.dirac (0:ℝ)) (Set.Iic 0)).toReal from rfl, h1]
  rfl

/-- 连续点的收敛：x < 0 处 Fₙ(x) = 0（对足够大的 n，
1/n > x）——逐点收敛于 μ-连续点的机器半边。 -/
example (x : ℝ) (hx : x < 0) (n : ℕ) (hn : 1 ≤ n) :
    Measure.real (Measure.dirac (1 / (n : ℝ))) (Set.Iic x) = 0 := by
  have h1 : (Measure.dirac (1 / (n : ℝ))) (Set.Iic x) = 0 := by
    rw [Measure.dirac_apply]
    have hnot : (1 / (n : ℝ)) ∉ Set.Iic x := by
      intro h
      have h3 : (0:ℝ) < 1 / (n : ℝ) := div_pos zero_lt_one (by exact_mod_cast hn)
      exact absurd (show (1:ℝ) / n ≤ 0 from le_of_lt (lt_of_le_of_lt h hx)) (not_le.2 h3)
    have hx2 : x < 1 / (n : ℝ) := by
      rw [one_div]
      exact hx.trans (inv_pos.2 (by exact_mod_cast hn))
    have hnx : ¬(1 / (n : ℝ) ≤ x) := not_le.2 hx2
    show Set.indicator (Set.Iic x) (fun _ => (1:ℝ≥0∞)) (1 / (n : ℝ)) = 0
    rw [Set.indicator_apply, if_neg (by simpa [Set.mem_Iic] using hnx)]
  rw [show Measure.real (Measure.dirac (1 / (n:ℝ))) (Set.Iic x)
      = ((Measure.dirac (1 / (n:ℝ))) (Set.Iic x)).toReal from rfl, h1]
  rfl
