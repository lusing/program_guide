import Mathlib.Probability.ProductMeasure

/-!
# 第 22 章 投影极限（Lean）

严书 §4.6。mathlib `Constructions/Projective.lean` 的谓词族即
本章主角：`IsProjectiveMeasureFamily`（相容族）、
`IsProjectiveLimit`（投影极限）、`measure_cylinder`（柱集账）、
`unique`（唯一性）；`Probability/ProductMeasure.lean` 给出
**乘积型相容族的完全体**：`Measure.infinitePi` 是 pi 族的投影
极限（`isProjectiveLimit_infinitePi`），且有限指标时与
`Measure.pi` 一致（`infinitePi_eq_pi`）。

实弹：Cantor 塔语境（Bool 因子）——infinitePi 的投影极限证书
拆开逐条对账：`infinitePi_map_restrict`（有限维边际）与
`eq_infinitePi`（唯一性判据）。
-/

open MeasureTheory
open scoped ENNReal

/-! ## 锚点正名 -/

#check @MeasureTheory.IsProjectiveMeasureFamily
#check @MeasureTheory.IsProjectiveLimit
#check @Measure.infinitePi
#check @Measure.isProjectiveLimit_infinitePi
#check @Measure.infinitePi_map_restrict
#check @Measure.eq_infinitePi
#check @Measure.infinitePi_eq_pi

/-! ## Cantor 塔：同一定理的两套坐标 -/

/-- Bernoulli(1/2) 因子（第 20 章同款）。 -/
noncomputable def bern2 : Measure Bool :=
  (2 : ℝ≥0∞)⁻¹ • (Measure.dirac true + Measure.dirac false)

instance : IsProbabilityMeasure bern2 := by
  constructor
  simp [bern2, Measure.smul_apply, Measure.add_apply, Set.indicator_of_mem, ENNReal.inv_two_add_inv_two]

/-- **乘积视角 ↔ 投影极限视角的换算表**：`isProjectiveLimit_
infinitePi` 断言无穷乘积是 pi 族的投影极限；逐项展开即
`infinitePi_map_restrict`（每个有限窗口 J 的边际 = 有限 pi）
——第 22.1 节"词典"的机器原文。 -/
example (J : Finset ℕ) :
    (Measure.infinitePi fun _ : ℕ => bern2).map J.restrict
      = Measure.pi fun _ : J => bern2 :=
  Measure.infinitePi_map_restrict _

/-! `eq_infinitePi`：唯一性的 usable 形态——任何测度若在一切
有限柱集上与无穷乘积同账，则它就是无穷乘积（柱集 π-系 +
第 06 章机器收口）。投影极限的"装配一致性检验"。 -/

#check @Measure.eq_infinitePi

/-- 有限指标时无穷乘积 = 有限 pi：塔在有限高度封顶，两套
坐标完全重合（`infinitePi_eq_pi`）。 -/
example : Measure.infinitePi (fun _ : Fin 3 => bern2) = Measure.pi fun _ : Fin 3 => bern2 :=
  Measure.infinitePi_eq_pi _
