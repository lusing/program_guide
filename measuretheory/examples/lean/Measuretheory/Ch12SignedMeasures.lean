import Mathlib.MeasureTheory.Measure.Decomposition.RadonNikodym
import Mathlib.MeasureTheory.VectorMeasure.Basic
import Mathlib.MeasureTheory.Measure.Decomposition.Hahn

/-!
# 第 12 章 符号测度与 Radon-Nikodym 定理（Lean）

严书 §3.3。机器锚点（`#check` 正名）：

* `MeasureTheory.SignedMeasure α`（= `VectorMeasure α ℝ` 的缩写，
  VectorMeasure/Basic.lean:73）；
* Hahn 分解：`IsHahnDecomposition` 结构与
  `exists_isHahnDecomposition`（Decomposition/Hahn.lean）；
* Lebesgue 分解：`haveLebesgueDecomposition_spec` /
  `singularPart_add_rnDeriv`（Decomposition/Lebesgue.lean）；
* **RN 定理本体**：`withDensity_rnDeriv_eq (μ ν) (h : μ ≪ ν) :
  ν.withDensity (rnDeriv μ ν) = μ`（Decomposition/RadonNikodym.lean:60）
  与 iff 形式 `absolutelyContinuous_iff_withDensity_rnDeriv_eq`。

实弹：密度测度的 RN 还原——μ = f·(dirac true) 对基测度绝对连续，
RN 方程把 f 从 μ 中"积分回来"；以及 rnDeriv 的可测性正名。
-/

open MeasureTheory
open scoped ENNReal

/-! ## 锚点正名 -/

#check @MeasureTheory.SignedMeasure
#check @MeasureTheory.IsHahnDecomposition
#check @MeasureTheory.exists_isHahnDecomposition
#check @MeasureTheory.Measure.singularPart_add_rnDeriv
#check @MeasureTheory.Measure.withDensity_rnDeriv_eq
#check @MeasureTheory.Measure.absolutelyContinuous_iff_withDensity_rnDeriv_eq

/-! ## 实弹：密度测度的 RN 还原 -/

/-- 密度 ⟹ 绝对连续（注 3.3.8(2) 的机器版）：f·ν ≪ ν。
（withDensity_absolutelyContinuous 在 MeasureTheory 根命名空间，
而 withDensity_rnDeriv_eq 在 MeasureTheory.Measure——同一文件
两级命名空间，裸名/限定名要分开写。） -/
example (ν : Measure Bool) (f : Bool → ℝ≥0∞) :
    ν.withDensity f ≪ ν :=
  withDensity_absolutelyContinuous ν f

/-- RN 方程（严书 3.3.11 的机器本体）：μ = f·ν 时，
ν 的 rnDeriv 把 μ 还原为密度形式。
`withDensity_rnDeriv_eq (μ ν) (h : μ ≪ ν) : ν.withDensity (rnDeriv μ ν) = μ`
一行收割——**结论里的基测度是第二个参数**（μ 是被还原者），
rnDeriv 的两个参数按 (被还原者, 基) 排。奇异部被绝对连续吞没
（`singularPart_eq_zero_of_ac` 的直读）。 -/
example (ν : Measure Bool) (f : Bool → ℝ≥0∞) (hf : Measurable f) :
    ν.withDensity ((ν.withDensity f).rnDeriv ν) = ν.withDensity f := by
  -- HaveLebesgueDecomposition 实例带 Measurable 前提，TC 搜不到，have 供入
  -- （Prop 类实例 plain have 即可被 TC 搜索使用，haveI 反被 linter 点名）
  have := Measure.haveLebesgueDecomposition_withDensity ν hf
  exact Measure.withDensity_rnDeriv_eq (ν.withDensity f) ν
    (withDensity_absolutelyContinuous ν f)

/-- RN 导数可测（作为密度函数的资格证）。 -/
example (μ ν : Measure Bool) : Measurable (μ.rnDeriv ν) :=
  Measure.measurable_rnDeriv μ ν
