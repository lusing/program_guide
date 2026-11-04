import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Add

/-!
# 第 06 章 未解出导数的方程：Clairut（Lean）

书 §2.6.3 + 习题 14：y = x·y' + (y')²。
- 通解直线族：y = Cx + C²（任意 C）逐字满足方程；
- 奇异解：y = -x²/4 也满足方程（包络）；
- 不在族中：不存在 C 使 -x²/4 ≡ Cx + C²——反证两行。
三份合起来是"通解 + 奇异解"概念的完整机器版。
-/

open Real

/-- 直线族解：y = Cx + C² 的导数是 C，而 x·C + C² 恰为 y——
代入方程 y = x·y' + (y')² 两边逐字相等。 -/
theorem clairaut_line (C : ℝ) (x : ℝ) :
    HasDerivAt (fun x => C * x + C ^ 2) C x ∧
    (fun x => C * x + C ^ 2) x = x * C + C ^ 2 := by
  constructor
  · have h1 : HasDerivAt (fun x => C * x) (C * 1) x :=
      HasDerivAt.const_mul C (hasDerivAt_id x)
    have h2 : HasDerivAt (fun x => C ^ 2) 0 x :=
      hasDerivAt_const (c := (C ^ 2 : ℝ)) (x := x)
    have h3 : HasDerivAt (fun x => C * x + C ^ 2) (C * 1 + 0) x :=
      HasDerivAt.add h1 h2
    exact h3.congr_deriv (by ring)
  · ring

/-- 奇异解：y = -x²/4 满足 y = x·y' + (y')²（y' = -x/2，
右端 x·(-x/2) + (-x/2)² = -x²/4 = y）。 -/
theorem clairaut_singular (x : ℝ) :
    HasDerivAt (fun x => -x ^ 2 / 4) (-x / 2) x ∧
    (fun x => -x ^ 2 / 4) x = x * (-x / 2) + (-x / 2) ^ 2 := by
  constructor
  · have h1 : HasDerivAt (fun x => x ^ 2) (2 * x) x := by
      simpa using hasDerivAt_pow 2 x
    have h2 : HasDerivAt (fun x => x ^ 2 / 4) (2 * x / 4) x :=
      HasDerivAt.div_const h1 4
    have h3 : HasDerivAt (fun x => -(x ^ 2 / 4)) (-(2 * x / 4)) x :=
      HasDerivAt.neg h2
    have hfun : ((fun x : ℝ => -x ^ 2 / 4) : ℝ → ℝ) = (fun x : ℝ => -(x ^ 2 / 4)) := by
      funext (z : ℝ); ring
    rw [hfun]
    exact h3.congr_deriv (by field_simp; ring)
  · field_simp
    ring

/-- 奇异解不在直线族中：若 -x²/4 = Cx + C² 对一切 x 成立，
取 x = 0 得 C² = 0 即 C = 0，取 x = 1 得 -1/4 = C + C² = 0，矛盾。 -/
theorem singular_not_in_family :
    ¬ ∃ C : ℝ, ∀ x : ℝ, -x ^ 2 / 4 = C * x + C ^ 2 := by
  rintro ⟨C, hC⟩
  have h0 : (0 : ℝ) = C ^ 2 := by
    have := hC 0
    simpa using this
  have hC0 : C = 0 := by
    have hz : C ^ 2 = 0 := by linarith
    exact pow_eq_zero_iff (two_ne_zero) |>.mp hz
  have h1 : (-1 : ℝ) / 4 = C * 1 + C ^ 2 := by
    have := hC 1
    simpa using this
  rw [hC0] at h1
  norm_num at h1
