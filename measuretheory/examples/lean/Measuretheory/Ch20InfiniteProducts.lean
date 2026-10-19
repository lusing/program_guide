import Mathlib.Probability.ProductMeasure

/-!
# 第 20 章 无穷乘积测度（Lean）

严书 §4.4。mathlib 4.33 实测口径（比 B0 侦察丰富）：
- 有限版：`Measure.pi`（[Fintype ι]）+ 柱集账 `Measure.pi_pi`；
- **无穷版**：`Probability/ProductMeasure.lean` 的
  `Measure.infinitePi μ`——任意族概率测度的无穷乘积，构造
  路线 = 柱集 AddContent（`piContent`）→ 验收引理
  `piContent_tendsto_zero`（正是"Cₙ ↓ ∅ ⟹ 账 ↓ 0"）→
  Carathéodory 延拓——与严书 §4.4 逐字同路；
- 配套：`isProjectiveLimit_infinitePi`（存在性=投影极限）、
  `infinitePi_map_restrict`（有限维边际 = 有限 pi）、
  `infinitePi_eq_pi`（有限指标一致）、`isProjectiveMeasureFamily_pi`
  （pi 族相容性）。

实弹：均匀硬币（Bool 上 ½·(δtrue+δfalse)）的有限 pi 账与
真无穷乘积（Bool^ℕ）的柱集账都是 2⁻ⁿ。
-/

open MeasureTheory
open scoped ENNReal

/-! ## 锚点正名 -/

#check @Measure.pi
#check @Measure.pi_pi
#check @measurable_pi_apply
#check @Measure.infinitePi
#check @Measure.isProjectiveLimit_infinitePi
#check @Measure.infinitePi_map_restrict
#check @MeasureTheory.isProjectiveMeasureFamily_pi

/-! ## 均匀硬币因子 -/

/-- Bernoulli(1/2)：½·(δtrue + δfalse)。 -/
noncomputable def bern2 : Measure Bool :=
  (2 : ℝ≥0∞)⁻¹ • (Measure.dirac true + Measure.dirac false)

instance : IsProbabilityMeasure bern2 := by
  constructor
  simp [bern2, Measure.smul_apply, Measure.add_apply, Set.indicator_of_mem, ENNReal.inv_two_add_inv_two]

/-- 因子账：bern2{true} = 2⁻¹——每个坐标"指定花样"的单价。 -/
example : bern2 ({true} : Set Bool) = (2 : ℝ≥0∞)⁻¹ := by
  simp [bern2, Measure.smul_apply, Measure.add_apply, Set.indicator_of_mem]

/-! ## 有限维账：n 坐标柱集 = 2⁻ⁿ -/

/-- 有限版：Fin n 上的独立乘积对"全 true"框的账 = ∏ 2⁻¹ =
2⁻ⁿ（`pi_pi` 拆框，因子单价逐个收割）。 -/
example (n : ℕ) :
    Measure.pi (fun _ : Fin n => bern2) (Set.pi Set.univ fun _ : Fin n => ({true} : Set Bool))
      = (2 : ℝ≥0∞)⁻¹ ^ n := by
  rw [Measure.pi_pi]
  simp [bern2, Measure.smul_apply, Measure.add_apply, Set.indicator_of_mem]

/-! ## 无穷版：Bool^ℕ 上的无穷乘积柱集账 -/

/-- 无穷次均匀硬币：Bool^ℕ 上的无穷乘积。 -/
noncomputable def coin : Measure (ℕ → Bool) := Measure.infinitePi fun _ : ℕ => bern2

/-- **无穷乘积的柱集账**：infinitePi 是 pi 族的投影极限
（`isProjectiveLimit_infinitePi`），`measure_cylinder` 给出柱集
账 = 有限维 pi 账——20.2 的"账本 P(柱) := 有限维账"机器原文。
本例：前 n 次全正面的概率 = 2⁻ⁿ。 -/
example (n : ℕ) :
    coin (cylinder (Finset.range n)
      (Set.pi Set.univ fun _ : ↥(Finset.range n) => ({true} : Set Bool)))
      = (2 : ℝ≥0∞)⁻¹ ^ n := by
  rw [show coin = Measure.infinitePi fun _ : ℕ => bern2 from rfl]
  rw [(Measure.isProjectiveLimit_infinitePi fun _ : ℕ => bern2).measure_cylinder
    (Finset.range n) (MeasurableSet.pi Set.countable_univ
      fun _ _ => measurableSet_singleton true)]
  rw [Measure.pi_pi]
  simp [bern2, Measure.smul_apply, Measure.add_apply, Set.indicator_of_mem]
