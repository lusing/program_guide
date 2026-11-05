import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv

/-!
# 第 17 章（Lean 通道）：中心显式对流扩散格式的稳定条件

对流扩散方程中心显式格式的增长因子

    G = 1 − 2mu(1−C) − ilamS   （C = cosθ_grid, S = sinθ_grid），

|G|² = 1 − (1−C)·B(C)，其中耗散括号

    B(C) = 4mu − 4mu²(1−C) − lam²(1+C)

关于 C 是**仿射函数**，因此是两端点值的凸组合：

    B(C) = ((1+C)/2)·B(1) + ((1−C)/2)·B(−1)。

两端点 B(1) = 4mu − 2lam²、B(−1) = 4mu − 8mu² 在书 (3.4)(3.5) 的条件
**lam² ≤ 2mu、2mu ≤ 1**（加上 mu ≥ 0）下非负，凸组合权重在 C ∈ [−1,1]
上非负 ⟹ B(C) ≥ 0 ⟹ |G|² ≤ 1。
-/

namespace Pdenum.Ch17

/-- **稳定方向的核**：`0 ≤ mu ≤ 1/2`、`lam² ≤ 2mu`、`C ∈ [−1,1]` 时
耗散括号 `B(C) = 4mu − 4mu²(1−C) − lam²(1+C) ≥ 0`。 -/
theorem central_cd_dissipative (mu lam C : ℝ) (hmu1 : 0 ≤ mu) (hmu2 : mu ≤ 1 / 2)
    (hlam : lam ^ 2 ≤ 2 * mu) (hC1 : -1 ≤ C) (hC2 : C ≤ 1) :
    0 ≤ 4 * mu - 4 * mu ^ 2 * (1 - C) - lam ^ 2 * (1 + C) := by
  -- 仿射函数 = 两端点的凸组合
  have hconv : 4 * mu - 4 * mu ^ 2 * (1 - C) - lam ^ 2 * (1 + C)
      = ((1 + C) / 2) * (4 * mu - 4 * mu ^ 2 * (1 - 1) - lam ^ 2 * (1 + 1))
      + ((1 - C) / 2) * (4 * mu - 4 * mu ^ 2 * (1 - (-1)) - lam ^ 2 * (1 + (-1))) := by
    ring
  have hB1 : 0 ≤ 4 * mu - 4 * mu ^ 2 * (1 - 1) - lam ^ 2 * (1 + 1) := by
    -- B(1) = 4mu − 2lam² ≥ 0（lam² ≤ 2mu）
    nlinarith [hlam]
  have hBm1 : 0 ≤ 4 * mu - 4 * mu ^ 2 * (1 - (-1)) - lam ^ 2 * (1 + (-1)) := by
    -- B(−1) = 4mu − 8mu² = 4mu(1 − 2mu) ≥ 0（mu ≤ 1/2）
    nlinarith
  have hw1 : 0 ≤ (1 + C) / 2 := by linarith
  have hw2 : 0 ≤ (1 - C) / 2 := by linarith
  have p1 := mul_nonneg hw1 hB1
  have p2 := mul_nonneg hw2 hBm1
  rw [hconv]
  linarith

end Pdenum.Ch17
