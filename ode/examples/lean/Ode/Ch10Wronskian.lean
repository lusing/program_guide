import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Add

/-!
# 第 10 章 Wronskian 与 Abel（Lean）

例 A：y₁ = eˣ 与 y₂ = e⁻ˣ 都是 y″ − y = 0 的解；
W(eˣ, e⁻ˣ) = eˣ·(−e⁻ˣ) − e⁻ˣ·eˣ = −2（常数——Abel 在 p = 0 时的
预言），逐字计算。
-/

open Real

namespace Ch10

/-- eˣ 满足 y″ − y = 0，即 y″ = y：一阶事实 e^x' = e^x 就够本层账。 -/
example (x : ℝ) : HasDerivAt (fun x => exp x) (exp x) x := hasDerivAt_exp x

/-- e⁻ˣ 满足方程：导数 = −e⁻ˣ。 -/
example (x : ℝ) : HasDerivAt (fun x => exp (-x)) (-(exp (-x))) x := by
  have hm : HasDerivAt (fun x : ℝ => -x) (-1 : ℝ) x := by
    simpa using (hasDerivAt_id x).const_mul (-1 : ℝ)
  have h := HasDerivAt.comp x (hasDerivAt_exp (-x)) hm
  simpa only [Function.comp_def, mul_one, mul_neg, neg_mul, one_mul] using h

/-- W(eˣ, e⁻ˣ) = −2 的逐字计算：乘积求导账 + exp_add 折叠。 -/
example (x : ℝ) :
    exp x * (-(exp (-x))) - exp (-x) * exp x = -2 := by
  have h : exp x * exp (-x) = 1 := by rw [← Real.exp_add]; norm_num
  linear_combination (-2) * h

/-- Abel 恒等式的 p = 0 情形：W 是常数 ⟹ W′ = 0。
数值点核对版：W 在任意两点的值相等。 -/
example (a b : ℝ) :
    exp a * (-(exp (-a))) - exp (-a) * exp a
      = exp b * (-(exp (-b))) - exp (-b) * exp b := by
  have h : exp a * exp (-a) = 1 := by rw [← Real.exp_add]; norm_num
  have h2 : exp b * exp (-b) = 1 := by rw [← Real.exp_add]; norm_num
  linear_combination (-2) * h + 2 * h2

end Ch10
