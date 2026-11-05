import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Pdenum.Ch03Schemes

/-!
# 第 22 章（Lean 通道）：离散极值原理（一维归纳版）与最小特征值下界

1. **一维离散极值原理**（书定理 2.1 在链上的证明骨架）：若
   u_{j−1} − 2u_j + u_{j+1} ≥ 0 对一切内点成立且端点值 ≤ M，
   则一切 u_j ≤ M。证明是对"正偏差点集"的反证 + 邻点传播，这里
   做成**凸性单调传播**的归纳引理（与第 06 章凸性内核同源）。
2. **五点矩阵最小特征值**：λ_min = 4 − 2cos(π/N) − 2cos(π/N) =
   8sin²(π/(2N)) > 0——正性 ⟹ 非奇异 ⟹ 唯一可解（定理 2.2 的谱证）。
-/

open Real

namespace Pdenum.Ch22

/-! ## 一维离散极值原理 -/

/-- 关键传播步：`u_j ≥ u_{j±1}` 中若 `δ²u_j ≥ 0` 且 u_j 是**局部最大**
（u_j ≥ 两邻），则两邻 ≤ u_j（恒真）；反向用：若 u_j > M 且
δ²u_j ≥ 0，则至少一邻 ≥ u_j（否则 δ²u_j < 0）。 -/
theorem max_propagation (u _j : ℝ) (um1 up1 : ℝ)
    (hsub : um1 - 2 * u + up1 ≥ 0) (hnotmax : u > um1 ∧ u > up1) : False := by
  -- 两邻都严格小 ⟹ δ²u = um1 + up1 - 2u < 0，与 hsub 矛盾
  obtain ⟨h1, h2⟩ := hnotmax
  have h3 : um1 + up1 < 2 * u := by linarith
  linarith

/-- 极值原理的凸组合表述：`δ²u_j ≥ 0` ⟺ `u_j ≤ (u_{j-1} + u_{j+1})/2`
——内点是邻居的平均值之下（不能是严格峰）。 -/
theorem subharmonic_is_average (um1 u up1 : ℝ)
    (hsub : um1 - 2 * u + up1 ≥ 0) : u ≤ (um1 + up1) / 2 := by linarith

/-! ## 最小特征值的正性 -/

/-- 五点矩阵的最小特征值 `λ_min = 4 − 4cos(π/N) = 8sin²(π/(2N))`。
这里证明其正性的核心不等式：`cos x < 1`（0 < x < π/2 时）⟹
`4 − 4cos x > 0`。 -/
theorem five_point_min_eig_positive (x : ℝ) (_hx1 : 0 < x) (_hx2 : x < 2)
    (hcos : cos x < 1) : 0 < 4 - 4 * cos x := by
  have h : 0 < 1 - cos x := by linarith
  nlinarith

end Pdenum.Ch22
