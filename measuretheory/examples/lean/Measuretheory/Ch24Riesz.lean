import Mathlib.MeasureTheory.Integral.RieszMarkovKakutani.Real

/-!
# 第 24 章 Riesz 表现定理（Lean）

严书 §5.2 / 袁上册 §11.2.3。mathlib 锚点（Integral/
RieszMarkovKakutani/ 三件）：NNReal 版 `rieszContent`（紧集
内容函数）→ `rieszMeasure`（延拓成测度）——**内容→测度两步
与严书 Daniell 路线同构**；Real 版（命名空间 `RealRMK`）：
`rieszMeasure`（实线性泛函的表现测度）、`integral_
rieszMeasure`（主定理 Λ f = ∫ f dμ）、`rieszMeasure_
integralPositiveLinearMap`（唯一性）。

实弹：点评价泛函的测度户口（δ 型泛函 ↔ dirac 测度，经
`integral_dirac` 收割）。
-/

open MeasureTheory RealRMK

/-! ## 锚点正名 -/

#check @RealRMK.rieszMeasure
#check @RealRMK.integral_rieszMeasure
#check @rieszMeasure_integralPositiveLinearMap
#check @rieszContent

/-! ## 点评价泛函的测度户口 -/

/-- 最简正线性泛函：点评价 I(f) = f(0)。其 Riesz 测度应为
δ₀——主定理陈述的"最小实例"（docs 24.6 断言 3 的机器侧）。 -/
example (f : ℝ → ℝ) : ∫ x, f x ∂(Measure.dirac (0:ℝ)) = f 0 :=
  integral_dirac f 0

/-- 泛函→测度的翻译条目（离散版）：δ₀(f) = f(0) 的积分账
与"点权泛函" Σ wᵢf(i) 的有限原形对齐——数值通道的 Julia/
Python 版由此展开。 -/
example : ∫ x, (x + 1) ∂(Measure.dirac (0:ℝ)) = 1 := by
  rw [integral_dirac _ 0]
  norm_num
