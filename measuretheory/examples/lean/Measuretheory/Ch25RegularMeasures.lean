import Mathlib.MeasureTheory.Measure.Lebesgue.Basic

/-!
# 第 25 章 正则测度与 Radon 测度（Lean）

严书 §5.3 / 袁上册 §11.2.1-11.2.2。mathlib 锚点（Measure/
Regular.lean）：class `OuterRegular`（开覆盖下确界）、
class `Regular`（extends IsFiniteMeasureOnCompacts +
OuterRegular + 紧内正则）、`InnerRegular` 族、instance 算术
（zero/smul/add）与 `Regular.weaklyRegular`。

实弹：Lebesgue 的正则性户口（volume 的 instance 引用——
本土定理的机器登记）、标量乘的封闭性。
-/

open MeasureTheory
open scoped NNReal

/-! ## 锚点正名 -/

#check @MeasureTheory.Measure.Regular
#check @MeasureTheory.Measure.OuterRegular
#check @MeasureTheory.Measure.InnerRegular
#check @MeasureTheory.Measure.InnerRegularCompactLTTop
#check @MeasureTheory.Measure.Regular.weaklyRegular

/-! ## instance 算术：封闭性的机器登记 -/

/-- 零测度的外正则（instance 算术的底座件）。 -/
example : Measure.OuterRegular (0 : Measure ℝ) := inferInstance

/-- 标量乘封闭：μ 外正则 ⟹ c•μ 外正则（Regular.lean 的
instance 套件——25.4 封闭性清单的机器形态）。 -/
example (μ : Measure ℝ) [Measure.OuterRegular μ] (c : ℝ≥0) :
    Measure.OuterRegular (c • μ) := inferInstance

