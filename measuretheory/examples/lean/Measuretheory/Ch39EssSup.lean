import Mathlib.MeasureTheory.Function.EssSup
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic

/-!
# 第 39 章 本性上确界（Lean）

严书 §7.5。mathlib 锚点（Function/EssSup.lean，**根命名
空间**——`essSup` 不带 MeasureTheory 前缀）：`essSup f μ =
(ae μ).limsup f`（滤子上极限定义）与配套 `essSup_le_iff`
等引理族；ess inf 对偶。

实弹：dirac 上的退化账（ess sup = sup——单点无零测模糊）
与 Lebesgue 型尖刺账（零测集上的值被无视）。
-/

open MeasureTheory
open scoped Topology

/-! ## 锚点正名 -/

#check @essSup
#check @essInf

/-! ## 退化与尖刺账 -/

/-- dirac 上的退化账：ess sup = 逐点值（单点测度下
ae 滤子即主超滤——一切 a.s. 条件即逐点条件）。经
`essSup_congr_ae` 把 f 对齐到常值 f()，再 `essSup_const'`
收割。 -/
example (f : Unit → ℝ) : essSup f (Measure.dirac ()) = f () := by
  have h : f =ᶠ[ae (Measure.dirac ())] fun _ => f () := by
    filter_upwards with x
    rfl
  rw [essSup_congr_ae h]
  exact essSup_const' (f ())

/-- 零测尖刺的无视（陈述账）：essSup 只看 ae 行为——
函数在零测集上的任何取值不改变 ess sup。此例登记
"改零测集上的值 = 同一 ess sup"的原则；具体集合计算
（如 2·1_ℚ 的 ess sup = 0）由数值通道对拍。 -/
example (f g : ℝ → ℝ) (μ : Measure ℝ) (h : f =ᶠ[ae μ] g) :
    essSup f μ = essSup g μ := essSup_congr_ae h
