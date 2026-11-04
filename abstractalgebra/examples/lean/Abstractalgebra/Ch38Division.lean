/-
! # 第 38 章 · 广义的除法算式

对应原书 §7.5。机器验证：多元除法的分解恒等式（定理 7.60 的
「f = Σ qᵢgᵢ + r」内核）与顺序依赖例的两组恒等式。
-/

import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum

namespace Abstractalgebra.Ch38

/-! ## 除法恒等式（原书例：lex 序） -/

-- f = x²y + xy² + y² 除以 [xy−1, y²−1]：lex 下的除法给出
-- q₁ = x+y、q₂ = 1、余式 r = x + y + 1（分解恒等式 f = q₁f₁ + q₂f₂ + r）
example : ∀ x y : ℚ,
    (x * x * y + x * y * y + y * y)
      = (x + y) * (x * y - 1) + 1 * (y * y - 1) + (x + y + 1) := by
  intro x y; ring

/-! ## 顺序依赖（余式不是理想成员判据） -/

-- f = xy² − x 除以 [xy+1, y²−1]：余式 −x−y
example : ∀ x y : ℚ,
    (x * y * y - x) = y * (x * y + 1) + 0 * (y * y - 1) + (-x - y) := by
  intro x y; ring

-- 同一 f 换序 [y²−1, xy+1]：余式 0（f 本就在理想中）
example : ∀ x y : ℚ,
    (x * y * y - x) = x * (y * y - 1) + 0 * (x * y + 1) + 0 := by
  intro x y; ring

/-! ## 首项乘法相容（命题 7.58 个案） -/

-- lt(fg) = lt(f)·lt(g)：(2x²+3)(5xy³−7x) 的首项 10x³y³
example : ∀ x y : ℚ,
    (2 * x ^ 2 + 3) * (5 * x * y ^ 3 - 7 * x)
      = 10 * x ^ 3 * y ^ 3 - 14 * x ^ 3 + 15 * x * y ^ 3 - 21 * x := by
  intro x y; ring

end Abstractalgebra.Ch38
