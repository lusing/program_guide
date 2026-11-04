/-
! # 第 20 章 · 多项式的唯一分解

对应原书 §3.6。机器验证：
1. F[x] 是唯一分解幺半群（mathlib 实例层）；
2. Sophie Germain 恒等式：x⁴+4 无根可约；
3. 唯一分解的规范形算例。
-/

import Mathlib.Algebra.Polynomial.Basic
import Mathlib.RingTheory.Polynomial.UniqueFactorization
import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith

namespace Abstractalgebra.Ch20

/-! ## F[x] 是 UFD -/

-- mathlib 事实：ℚ[x] 是欧几里得整环，从而是唯一分解整环
-- （EuclideanDomain → UFD 的实例链在 Mathlib.RingTheory.EuclideanDomain 中）
noncomputable example : EuclideanDomain (Polynomial ℚ) := inferInstance

/-! ## Sophie Germain 恒等式：x⁴ + 4 的分解 -/

example : (Polynomial.X ^ 4 + 4 : Polynomial ℚ)
      = (Polynomial.X ^ 2 - 2 * Polynomial.X + 2) *
        (Polynomial.X ^ 2 + 2 * Polynomial.X + 2) := by ring

-- 数值侧写（整数版）
example : 5 ^ 4 + 4 = (25 - 10 + 2) * (25 + 10 + 2) := by norm_num

-- x⁴ + 4 在 ℚ 上可约（上面的分解即证据）——"无根 ≠ 不可约"的机器版

/-! ## 规范形算例 -/

-- x⁴ − x² 在 ℚ[x] = x²(x−1)(x+1)（全部因子一次或二次）
example : (Polynomial.X ^ 4 - Polynomial.X ^ 2 : Polynomial ℚ)
      = Polynomial.X ^ 2 * (Polynomial.X - 1) * (Polynomial.X + 1) := by ring

-- x⁴ + x² + 1 = (x²+x+1)(x²−x+1)（隐蔽的二次分解）
example : (Polynomial.X ^ 4 + Polynomial.X ^ 2 + 1 : Polynomial ℚ)
      = (Polynomial.X ^ 2 + Polynomial.X + 1) * (Polynomial.X ^ 2 - Polynomial.X + 1) := by
  ring

end Abstractalgebra.Ch20
