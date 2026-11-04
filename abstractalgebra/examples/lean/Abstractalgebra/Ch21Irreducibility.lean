/-
! # 第 21 章 · 不可约性判别

对应原书 §3.7。机器验证：
1. Eisenstein 判别的实例（x⁵ − 4x + 2，p = 2）；
2. Φ_p(x+1) 的二项系数整除性（分圆不可约的引擎）；
3. 逐系数的整除条件核对。
-/

import Mathlib.Algebra.Polynomial.Basic
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.RingTheory.Polynomial.Cyclotomic.Basic
import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith

namespace Abstractalgebra.Ch21

/-! ## Eisenstein 实例：x⁵ − 4x + 2（p = 2） -/

-- 系数 [2, 0, 0, −4, 0, 1]（常数到首项）：除首项外全被 2 整除
example : ∀ c ∈ [2, 0, 0, 4, 0], 2 ∣ c := by decide

-- 首项系数 1 不被 2 整除
example : ¬ 2 ∣ (1 : ℕ) := by decide

-- 常数项 2 不被 4 整除（p² 条件）
example : ¬ 4 ∣ (2 : ℕ) := by decide

-- 三条件齐备 ⟹ Eisenstein 判别适用（结论：ℚ[x] 不可约，正文的数学证明）
-- 求值断言以显式展开书写（避免 noncomputable Polynomial 的 decide 卡壳）
example : (Polynomial.X ^ 5 - 4 * Polynomial.X + 2 : Polynomial ℚ).eval 1 = -1 := by
  norm_num [Polynomial.eval_sub, Polynomial.eval_add, Polynomial.eval_pow,
            Polynomial.eval_mul, Polynomial.eval_X]

example : (Polynomial.X ^ 5 - 4 * Polynomial.X + 2 : Polynomial ℚ).eval (-1) = 5 := by
  norm_num [Polynomial.eval_sub, Polynomial.eval_add, Polynomial.eval_pow,
            Polynomial.eval_mul, Polynomial.eval_X]

example : (Polynomial.X ^ 5 - 4 * Polynomial.X + 2 : Polynomial ℚ).eval 2 = 26 := by
  norm_num [Polynomial.eval_sub, Polynomial.eval_add, Polynomial.eval_pow,
            Polynomial.eval_mul, Polynomial.eval_X]

example : (Polynomial.X ^ 5 - 4 * Polynomial.X + 2 : Polynomial ℚ).eval (-2) = -22 := by
  norm_num [Polynomial.eval_sub, Polynomial.eval_add, Polynomial.eval_pow,
            Polynomial.eval_mul, Polynomial.eval_X]

/-! ## 分圆引擎：Φ_p(x+1) 的二项系数 -/

-- p = 5：C(5,k) 对 1 ≤ k ≤ 4 全被 5 整除
example : ∀ k ∈ [1, 2, 3, 4], 5 ∣ Nat.choose 5 k := by decide

-- Φ₅(x+1) = ((x+1)⁵ − 1)/x = x⁴ + 5x³ + 10x² + 10x + 5：系数即 C(5,k)
example : ((Polynomial.X + 1 : Polynomial ℚ) ^ 5 - 1)
      = Polynomial.X * (Polynomial.X ^ 4 + 5 * Polynomial.X ^ 3
          + 10 * Polynomial.X ^ 2 + 10 * Polynomial.X + 5) := by
  ring

end Abstractalgebra.Ch21
