import Mathlib.Tactic

/-!
# 第 31 章：统计模型与风险（Lean）

这里形式化偏差—方差恒等式，以及正态方差估计量 `cS²` 的精确风险。
识别与模型误设是分布层面的概念，正文给出定义与反例。
-/

namespace Ch31

/-- 平方误差风险分成偏差平方与方差两项。 -/
def squaredRisk (bias variance : ℚ) : ℚ := bias ^ 2 + variance

/-- `a·X̄` 估计均值 `μ` 时，直接风险与分解后的风险一致。 -/
theorem mse_decomposition (a μ σ2 n : ℚ) :
    squaredRisk ((a - 1) * μ) (a ^ 2 * σ2 / n) =
      (a - 1) ^ 2 * μ ^ 2 + a ^ 2 * σ2 / n := by
  simp only [squaredRisk]
  ring

/-- 正态模型中，`Q=(n-1)S²/σ²~χ²_ν`，故 `cS²` 的标准化风险如下。 -/
def scaledVarianceRisk (c ν : ℚ) : ℚ :=
  (1 + 2 / ν) * c ^ 2 - 2 * c + 1

/-- 无偏估计 `c=1` 仍有正风险 `2/ν`。 -/
theorem risk_unbiased (ν : ℚ) (hν : ν ≠ 0) :
    scaledVarianceRisk 1 ν = 2 / ν := by
  simp only [scaledVarianceRisk]
  field_simp
  ring

/-- 在固定正态模型和固定 `ν` 下，平方误差最优缩放为 `ν/(ν+2)`。 -/
theorem risk_optimal (ν : ℚ) (hν : ν ≠ 0) (hν2 : ν + 2 ≠ 0) :
    scaledVarianceRisk (ν / (ν + 2)) ν = 2 / (ν + 2) := by
  simp only [scaledVarianceRisk]
  field_simp
  ring

/-- 完全平方恒等式同时证明最优性和唯一性，而不只检查导数为零。 -/
theorem risk_gap (c ν : ℚ) (hν : ν ≠ 0) (hν2 : ν + 2 ≠ 0) :
    scaledVarianceRisk c ν - scaledVarianceRisk (ν / (ν + 2)) ν =
      (1 + 2 / ν) * (c - ν / (ν + 2)) ^ 2 := by
  simp only [scaledVarianceRisk]
  field_simp
  ring

/-- MLE 使用 `c=(n-1)/n`，其风险介于无偏估计与最优缩放之间。 -/
theorem normal_mle_risk (n : ℚ) (hn : n ≠ 0) (hn1 : n - 1 ≠ 0) :
    scaledVarianceRisk ((n - 1) / n) (n - 1) = (2 * n - 1) / n ^ 2 := by
  simp only [scaledVarianceRisk]
  field_simp
  ring

/-- `n=10` 的三种标准化风险严格递减：无偏、MLE、风险最优。 -/
example :
    (2 / 11 : ℚ) < 19 / 100 ∧ (19 / 100 : ℚ) < 2 / 9 := by
  norm_num

end Ch31
