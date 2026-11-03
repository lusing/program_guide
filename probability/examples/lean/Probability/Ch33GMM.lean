import Mathlib.Tactic

/-!
# 第 33 章：GMM 最优权重的标量代数锚

两个独立均值测量等价于两个线性矩条件。这里用完全平方证明
逆方差加权达到该类线性组合的最小渐近方差。
-/

namespace Ch33

/-- 归一化权重为 `(a,1-a)` 时，两个独立测量的方差。 -/
def twoMeasurementVariance (a s1 s2 : ℚ) : ℚ :=
  a ^ 2 * s1 + (1 - a) ^ 2 * s2

/-- 逆方差加权对应 `a=s2/(s1+s2)`。 -/
def optimalFirstWeight (s1 s2 : ℚ) : ℚ := s2 / (s1 + s2)

/-- 任意权重与逆方差权重的方差差是一个非负完全平方的倍数。 -/
theorem two_measurement_variance_gap (a s1 s2 : ℚ) (hs : s1 + s2 ≠ 0) :
    twoMeasurementVariance a s1 s2 -
        twoMeasurementVariance (optimalFirstWeight s1 s2) s1 s2 =
      (s1 + s2) * (a - optimalFirstWeight s1 s2) ^ 2 := by
  simp only [twoMeasurementVariance, optimalFirstWeight]
  field_simp
  ring

/-- 最优方差是并联精度公式 `s1*s2/(s1+s2)`。 -/
theorem two_measurement_optimal_variance (s1 s2 : ℚ) (hs : s1 + s2 ≠ 0) :
    twoMeasurementVariance (optimalFirstWeight s1 s2) s1 s2 =
      s1 * s2 / (s1 + s2) := by
  simp only [twoMeasurementVariance, optimalFirstWeight]
  field_simp
  ring

/-- 本章数值例：方差为 `1,4` 时最优第一权重为 `4/5`，最优方差为 `4/5`。 -/
example : optimalFirstWeight 1 4 = 4 / 5 := by norm_num [optimalFirstWeight]

example : twoMeasurementVariance (4 / 5) 1 4 = 4 / 5 := by
  norm_num [twoMeasurementVariance]

end Ch33
