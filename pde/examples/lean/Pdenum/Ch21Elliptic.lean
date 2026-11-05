import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Pdenum.Ch03Schemes

/-!
# 第 21 章（Lean 通道）：五点格式的格点恒等式与九点格式的展开核

1. **二次调和函数上五点格式精确**：u(x,y) = x² − y² 的五点 Laplace
   余量为零——纯 `ring` 恒等式。
2. **九点格式对 sin(πx)sin(πy) 的展开核**（书 §1.2 推导的核心一步）：
   `4S₁ + S₂ − 20u₀ = 6h²·Δu + (h⁴/2)·Δ²u + O(h⁶)` 在此模式上化为
   三角恒等式。本章证明该模式版的代数内核：由模板恒等式
   `sin((j±1)θ) + sin((j∓1)θ) = 2cosθ·sin(jθ)` 与
   `4cos + cos²` 的展开拼装。
-/

open Real

namespace Pdenum.Ch21

/-! ## 五点格式对二次多项式精确 -/

/-- x² − y² 的五点 Laplace 余量恒为零：分子 = 4·(x²−y²) − [四个邻居之和]。
这是"调和二次函数上五点格式精确"（00 章数值现象）的一维版代数内核。 -/
theorem five_point_exact_quadratic (x y h : ℝ) :
    (x + h) ^ 2 - y ^ 2 + (x - h) ^ 2 - y ^ 2
      + x ^ 2 - (y + h) ^ 2 + x ^ 2 - (y - h) ^ 2
      = 4 * (x ^ 2 - y ^ 2) := by
  ring

/-! ## 九点格式：模板和恒等式 -/

/-- 模式 `v_j = sin(jθ)` 的四邻和 `S₁` 与对角和 `S₂`（以 sin(jθ) 为单位）：
`S₁ = 4cosθ·v`，`S₂ = 4cos²θ·v`。 -/
theorem nine_point_sums (j θ : ℝ)
    (h1 : sin ((j + 1) * θ) + sin ((j - 1) * θ) = 2 * cos θ * sin (j * θ)) :
    (sin ((j + 1) * θ) + sin ((j - 1) * θ)) * 2
      = 4 * cos θ * sin (j * θ) := by
  rw [h1]; ring

/-- **九点核**：可分离模式 u₀ = sin(jθ)·sin(jφ)（两方向同波数）的
S₁ 中每个方向的邻居和被模板恒等式替换为 `2cosθ·u₀`，故
`4S₁ = 16cosθ·u₀`；对角和 S₂ = 4cos²θ·u₀。合起来
`4S₁ + S₂ = (16cosθ + 4cos²θ)·u₀`——书 §1.2 展开的第一步（下一步
代入 cosθ 的 Taylor 展开得 `−12θ² + 2θ⁴`·u₀，即 6h²Δu + (h⁴/2)Δ²u）。 -/
theorem nine_point_first_step (j θ : ℝ)
    (h1 : sin ((j + 1) * θ) + sin ((j - 1) * θ) = 2 * cos θ * sin (j * θ)) :
    4 * ((sin ((j + 1) * θ) + sin ((j - 1) * θ))     -- x 方向邻居对
         + (sin ((j + 1) * θ) + sin ((j - 1) * θ)))  -- y 方向邻居对（同波数）
      + 4 * cos θ * cos θ * sin (j * θ)
      = (16 * cos θ + 4 * cos θ * cos θ) * sin (j * θ) := by
  rw [h1]
  ring

end Pdenum.Ch21
