import Mathlib.Tactic

/-!
# 第 34 章：信息下界与有效性的代数锚
-/

namespace Ch34

/-- 参数函数 `ψ` 的标量 Cramér–Rao 下界。 -/
def cramerRaoBound (psiPrime information : ℚ) : ℚ :=
  psiPrime ^ 2 / information

/-- 一旦得到 Cauchy–Schwarz 形式 `c²≤v*i`，除以正信息即为 CR 形式。 -/
theorem cramer_rao_from_cauchy (v i c : ℚ) (hi : 0 < i)
    (hcs : c ^ 2 ≤ v * i) : c ^ 2 / i ≤ v := by
  exact (div_le_iff₀ hi).2 hcs

/-- Bernoulli 均值的方差与下界相同。 -/
theorem bernoulli_attains_bound (n p : ℚ) (hp : p ≠ 0) (hp1 : 1 - p ≠ 0)
    (hn : n ≠ 0) :
    p * (1 - p) / n = cramerRaoBound 1 (n / (p * (1 - p))) := by
  simp only [cramerRaoBound]
  field_simp

/-- 均值未知时，正态方差的无偏样本方差与 CR 下界之差。 -/
theorem normal_variance_gap (n v : ℚ) (hn : n ≠ 0) (hn1 : n - 1 ≠ 0) :
    2 * v ^ 2 / (n - 1) - 2 * v ^ 2 / n =
      2 * v ^ 2 / (n * (n - 1)) := by
  field_simp
  ring

/-- 未达到下界与不是 UMVU 是两件事；本例的效率为 `(n-1)/n`。 -/
theorem normal_variance_efficiency (n v : ℚ) (hn : n ≠ 0)
    (hn1 : n - 1 ≠ 0) (hv : v ≠ 0) :
    (2 * v ^ 2 / n) / (2 * v ^ 2 / (n - 1)) = (n - 1) / n := by
  field_simp

end Ch34
