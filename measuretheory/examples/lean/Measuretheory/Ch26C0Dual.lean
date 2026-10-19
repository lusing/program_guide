import Mathlib.MeasureTheory.Integral.RieszMarkovKakutani.Real
import Mathlib.MeasureTheory.Integral.BoundedContinuousFunction
import Mathlib.MeasureTheory.Measure.Decomposition.Hahn
import Mathlib.MeasureTheory.VectorMeasure.Basic
import Mathlib.MeasureTheory.VectorMeasure.Decomposition.Jordan

/-!
# 第 26 章 C₀(X) 的对偶（Lean）

严书 §5.4 / 袁上册 §11.2.3 后半。**分工如实**：mathlib 无
符号版 RMK 的打包定理（`RealRMK` 只收正线性泛函；`SignedMeasure`
的 Jordan 分解在第 12 章层）。本章机器侧：正情形主定理锚点 +
有界连续函数的积分件（对偶配对的原材料）+ Jordan 零件清单。

实弹：点评价泛函 δ₀ 的账（正情形的 Riesz 实弹）与有界
非负连续函数的 lintegral 有限性（C₀ 泛函连续性的原料）。
-/

open MeasureTheory RealRMK BoundedContinuousFunction
open scoped NNReal BoundedContinuousFunction

/-! ## 锚点正名 -/

#check @RealRMK.integral_rieszMeasure
#check @BoundedContinuousFunction.lintegral_lt_top_of_nnreal
#check @MeasureTheory.SignedMeasure
#check @MeasureTheory.SignedMeasure.totalVariation

/-! ## 正情形实弹：评价泛函与对偶配对 -/

/-- 评价泛函的积分账：δ₀(f) = f(0)（正线性泛函的最小实例，
其 RMK 表现测度 = dirac）。 -/
example (f : ℝ → ℝ) :
    ∫ x, f x ∂(Measure.dirac (0:ℝ)) = f 0 :=
  integral_dirac f 0

/-! 对偶配对的原料：有限测度下有界非负连续函数的积分有限
（`lintegral_lt_top_of_nnreal`——泛函 Λ_ν(f) = ∫f dν 良定义
的机器前提，陈述见上方 #check）。 -/
