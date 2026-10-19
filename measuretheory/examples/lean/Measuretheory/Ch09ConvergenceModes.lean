import Mathlib.MeasureTheory.Function.Egorov
import Mathlib.MeasureTheory.Function.ConvergenceInMeasure
import Mathlib.MeasureTheory.Measure.Dirac
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.Analysis.SpecificLimits.Basic

/-!
# 第 09 章 可测函数序列的收敛（Lean）

严书 §2.3。机器锚点三件套（`#check` 验证正名）：

* `MeasureTheory.TendstoInMeasure`（依测度收敛，Function/
  ConvergenceInMeasure.lean:57）；
* `TendstoInMeasure.exists_seq_tendsto_ae`（Riesz 子列定理）与
  `exists_seq_tendstoInMeasure_atTop_iff`（子列刻画，需有限测度，
  严书 2.3.6 的机器版）；
* `tendstoUniformlyOn_of_ae_tendsto`（Egorov，Function/Egorov.lean）；
* `tendstoInMeasure_of_tendsto_ae`（有限测度上 a.e. ⟹ 依测度，
  严书 2.3.5(1) 的机器版）。

实弹两发：[0,1] 上 xⁿ 的 Egorov 挖集，与狄拉克测度上的
"a.e. ⟹ 依测度"。

实施记要（坑）：① 裸写 `Tendsto`/`𝓝`/`atTop` 必须 `open Filter`，
否则 autoImplicit 把它当未知变量吞掉；② ℝ 上 volume 有两副实例
面孔（MeasureSpace 派生 vs `Real.measurableSpace`），缝合处易炸——
a.e. 陈述改带自由测度参数 + 零点集假设，调用处再喂 volume，
绕开实例打架；③ `AEStronglyMeasurable` 是 ∃ 定义
（∃ g, StronglyMeasurable g ∧ f =ᵐ g），证据直接给 ⟨g, _, _⟩。
-/

open MeasureTheory
open Filter
open scoped Topology
open scoped ENNReal

/-! ## 锚点正名（构建期打印签名） -/

#check @MeasureTheory.TendstoInMeasure
#check @MeasureTheory.TendstoInMeasure.exists_seq_tendsto_ae
#check @MeasureTheory.exists_seq_tendstoInMeasure_atTop_iff
#check @MeasureTheory.tendstoUniformlyOn_of_ae_tendsto
#check @MeasureTheory.tendstoInMeasure_of_tendsto_ae

/-! ## Egorov 实弹：[0,1] 上 fₙ(x) = xⁿ -/

/-- a.e. 收敛的前提（带自由测度）：只要 {1} 是 μ-零测集，除
x = 1 外 [0,1] 中的 x 都有 xⁿ → 0（"x ∉ Icc 时前提空真"由蕴含式
吸收）。 -/
private theorem ae_tendsto_pow {μ : Measure ℝ} (h1 : μ ({1} : Set ℝ) = 0) :
    ∀ᵐ x ∂μ, x ∈ Set.Icc (0:ℝ) 1 →
      Tendsto (fun n : ℕ => x ^ n) atTop (𝓝 (0:ℝ)) := by
  rw [ae_iff]
  have hsub : {x : ℝ | ¬(x ∈ Set.Icc (0:ℝ) 1 →
      Tendsto (fun n : ℕ => x ^ n) atTop (𝓝 (0:ℝ)))} ⊆ ({1} : Set ℝ) := by
    intro x hx
    simp only [Set.mem_ofPred_eq] at hx
    push Not at hx
    obtain ⟨hmem, hnot⟩ := hx
    by_contra hc
    have hx1 : x ≠ 1 := fun he => hc (by simp [he])
    have hxlt1 : x < 1 := lt_of_le_of_ne hmem.2 hx1
    exact hnot (tendsto_pow_atTop_nhds_zero_of_lt_one hmem.1 hxlt1)
  exact measure_mono_null hsub h1

/-- Egorov 定理的完整产物：存在挖集 t ⊆ [0,1]，volume t ≤ 1/8，
且在 [0,1]∖t 上 xⁿ **一致**收敛于 0。 -/
example : ∃ t ⊆ (Set.Icc (0:ℝ) 1),
    MeasurableSet t ∧ (volume : Measure ℝ) t ≤ ENNReal.ofReal (1/8) ∧
    TendstoUniformlyOn (fun n (x : ℝ) => x ^ n) (fun _ => (0:ℝ)) atTop
      (Set.Icc (0:ℝ) 1 \ t) := by
  have hmeas : ∀ n : ℕ, StronglyMeasurable fun (x : ℝ) => x ^ n := fun n =>
    (continuous_pow n).stronglyMeasurable
  have hs : (volume : Measure ℝ) (Set.Icc (0:ℝ) 1) ≠ ∞ := by
    rw [Real.volume_Icc]
    simp
  refine tendstoUniformlyOn_of_ae_tendsto hmeas stronglyMeasurable_const
    measurableSet_Icc hs
    (ae_tendsto_pow (Set.Finite.measure_zero (Set.finite_singleton 1) _))
    (by norm_num)

/-! ## 有限测度：a.e. ⟹ 依测度（严书 2.3.5(1) 机器版） -/

/-- 狄拉克质量是有限测度；常值函数列 (1/2)ⁿ 处处收敛于 0，
机器版定理直接给出依测度收敛。 -/
example : TendstoInMeasure (Measure.dirac (true : Bool))
    (fun n (_ : Bool) => (1/2 : ℝ) ^ n) atTop (fun _ => 0) :=
  tendstoInMeasure_of_tendsto_ae
    (fun n => ⟨fun _ => (1/2 : ℝ) ^ n, stronglyMeasurable_const, by simp⟩)
    (ae_of_all _ fun _ =>
      tendsto_pow_atTop_nhds_zero_of_lt_one (by norm_num) (by norm_num))
