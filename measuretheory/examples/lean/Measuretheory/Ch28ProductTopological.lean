import Mathlib.MeasureTheory.Measure.Prod
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.MeasureTheory.Constructions.BorelSpace.Basic

/-!
# 第 28 章 拓扑乘积上的测度（Lean）

严书 §5.6 / 袁上册 §11.4。mathlib 锚点：σ-代数对齐
`prod_le_borel_prod`（乘积 σ-代数 ≤ Borel 乘积；第二可数下
instance 取等——第 23 章）、矩形账 `Measure.prod_prod`（紧
有限传递的机器一步：K ⊆ K₁×K₂ 的账由矩形账单调控制）。

实弹：紧矩形上的体积账（紧有限传递：Icc ×ˢ Icc 的账 =
1·1 = 1）与 BorelSpace 乘积登记。
-/

open MeasureTheory

/-! ## 锚点正名 -/

#check @prod_le_borel_prod
#check @BorelSpace
#check @Measure.prod_prod

/-! ## σ-代数对齐 -/

/-- 乘积对齐的 ≤ 半边：B(ℝ) ⊗ B(ℝ) ≤ B(ℝ×ℝ)（投影连续）。 -/
example : Prod.instMeasurableSpace ≤ borel (ℝ × ℝ) :=
  prod_le_borel_prod

/-- 取等的 instance 形态（第二可数补齐另一方向）。 -/
example : BorelSpace (ℝ × ℝ) := inferInstance

/-! ## 紧有限传递：矩形账一步 -/

/-- 紧矩形的账：[0,1]×[0,1] 的 Lebesgue 乘积账 = 1·1 = 1
——"投影紧 ⟹ 账被 μ(K₁)ν(K₂) 控制"的等号现场（28.2
第一步的机器版）。 -/
example : Measure.prod volume (volume : Measure ℝ)
    (Set.Icc (0:ℝ) 1 ×ˢ Set.Icc (0:ℝ) 1) = 1 := by
  rw [Measure.prod_prod]
  simp [Real.volume_Icc]
