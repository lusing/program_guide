import Mathlib

/-!
# Ch13 Hamilton-Jacobi I：Legendre 变换的代数核

对应书 §3.3.2（Legendre 变换、Hopf-Lax 公式）。对凸 Hamilton 量
H(p) = p²/2，其 Legendre 对偶是 L(v) = v²/2，对偶关系

    H(p) = max_v [pv − L(v)]

的核心是**配方恒等式** pv − v²/2 = p²/2 − (v−p)²/2 ≤ p²/2，
在 v = p 处取等。本文件完整证明恒等式与极小性质——这就是
Hopf-Lax 公式 min_y [tL((y−x)/t) + g(y)] 中"对 y 求最小可显式解出"
的全部代数。
-/

namespace Evanspde.Ch13

/-- **配方恒等式**：pv − v²/2 = p²/2 − (v−p)²/2。 -/
theorem legendre_square (p v : ℝ) : p * v - v ^ 2 / 2 = p ^ 2 / 2 - (v - p) ^ 2 / 2 := by
  ring

/-- **对偶上界**：pv − v²/2 ≤ p²/2，即 H(p) = p²/2 是 Legendre
变换的值。 -/
theorem legendre_le (p v : ℝ) : p * v - v ^ 2 / 2 ≤ p ^ 2 / 2 := by
  rw [legendre_square p v]
  have : (v - p) ^ 2 / 2 ≥ 0 := by positivity
  linarith

/-- **取等点**：v = p 时 Legendre 变换达到 H(p)。 -/
theorem legendre_eq (p : ℝ) : p * p - p ^ 2 / 2 = p ^ 2 / 2 := by ring

end Evanspde.Ch13
