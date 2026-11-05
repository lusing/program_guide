import Mathlib

/-!
# Ch04 Laplace 方程 II：镜像法恒等式的完整机器证明

对应书 §2.2.4（Green 函数：corrector、表示公式、对称性、球的
Green 函数与镜像法）。球的 Green 函数（n 维）取

    G(x,y) = Φ(y−x) − Φ(|x|·|y−x*|)，x* = x/|x|²（反演点），

它在边界 |y| = 1 上恒为零，其代数核是恒等式

    |y − x|² = |x|² · |y − x/|x|²|²    （|y| = 1）。

本文件对二维情形完整证明：先证**差的显式分解**（两侧之差恰为
(1−|x|²)(|y|²−1)），边界条件 |y|² = 1 代入即得恒等式。
Φ 层面的结论（G = 0 于边界、对称性）在 Julia 通道数值验证。
-/

open Real

namespace Evanspde.Ch04

/-- **差的显式分解**：恒等式两侧之差 = (1−|x|²)(|y|²−1)——
可见 |y|² = 1 时恒等式成立（这正是镜像法有效的原因）。 -/
theorem image_identity_diff (x1 x2 y1 y2 : ℝ) (hx : x1 ^ 2 + x2 ^ 2 ≠ 0) :
    (y1 - x1) ^ 2 + (y2 - x2) ^ 2
      - (x1 ^ 2 + x2 ^ 2) *
          ((y1 - x1 / (x1 ^ 2 + x2 ^ 2)) ^ 2
            + (y2 - x2 / (x1 ^ 2 + x2 ^ 2)) ^ 2)
      = (1 - (x1 ^ 2 + x2 ^ 2)) * (y1 ^ 2 + y2 ^ 2 - 1) := by
  field_simp
  ring

/-- **镜像法恒等式（书 §2.2.4 球的 Green 函数的核心计算）**：
单位圆上 |y−x|² = |x|²·|y−x*|²，其中 x* = x/|x|² 是反演点。 -/
theorem image_identity (x1 x2 y1 y2 : ℝ) (hx : x1 ^ 2 + x2 ^ 2 ≠ 0)
    (hy : y1 ^ 2 + y2 ^ 2 = 1) :
    (y1 - x1) ^ 2 + (y2 - x2) ^ 2
      = (x1 ^ 2 + x2 ^ 2) *
          ((y1 - x1 / (x1 ^ 2 + x2 ^ 2)) ^ 2
            + (y2 - x2 / (x1 ^ 2 + x2 ^ 2)) ^ 2) := by
  have h := image_identity_diff x1 x2 y1 y2 hx
  rw [hy] at h
  simp at h
  linarith

end Evanspde.Ch04
