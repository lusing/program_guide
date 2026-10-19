import Mathlib.MeasureTheory.Integral.Lebesgue.Add
import Mathlib.MeasureTheory.Integral.Lebesgue.Countable
import Mathlib.MeasureTheory.Integral.DominatedConvergence
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic

/-!
# 第 11 章 积分号下取极限（Lean）

严书 §3.2。三大定理的机器对应物（`#check` 正名）：

* 单调收敛 MCT：`lintegral_iSup`（Add.lean:34）与极限形式
  `lintegral_tendsto_of_tendsto_of_monotone`（Add.lean:113）；
* Fatou 引理：`lintegral_liminf_le`（Add.lean:231）；
* 控制收敛 DCT：`tendsto_integral_of_dominated_convergence`
  （DominatedConvergence.lean:57，Bochner 值）。

实弹两发：狄拉克质量上的 MCT（单调性与逐点极限都是干净的手工件，
积分逐项 = 函数值由 `lintegral_dirac'` 收割）；[0,1] 上 xⁿ 的 DCT
（|xⁿ| ≤ 1 可积、a.e. → 0，机器直接给出 ∫ xⁿ → 0——第 09 章
a.e. 骨架的积分层收割）。
-/

open MeasureTheory
open Filter
open scoped Topology ENNReal

/-! ## 锚点正名 -/

#check @MeasureTheory.lintegral_iSup
#check @MeasureTheory.lintegral_tendsto_of_tendsto_of_monotone
#check @MeasureTheory.lintegral_liminf_le
#check @MeasureTheory.tendsto_integral_of_dominated_convergence

/-! ## MCT 实弹（狄拉克质量上的干净列） -/

/-- MCT（严书 3.2.1(1) 的机器版）：fₙ = n ⊓ 1 常值列单调升到 1，
积分列收敛到极限函数的积分（在狄拉克质量上逐项 = 函数值）。 -/
example : Tendsto (fun n => ∫⁻ _ : Bool, ((n : ℕ) : ℝ≥0∞) ⊓ 1
    ∂(Measure.dirac true)) atTop (𝓝 1) := by
  have hfin : ∫⁻ _ : Bool, (1:ℝ≥0∞) ∂(Measure.dirac true) = 1 := by
    rw [lintegral_const]
    simp
  have key := lintegral_tendsto_of_tendsto_of_monotone
    (f := fun n (_ : Bool) => ((n : ℕ) : ℝ≥0∞) ⊓ 1) (F := fun _ => (1:ℝ≥0∞))
    (fun _ => measurable_const.aemeasurable)
    (ae_of_all (Measure.dirac (true : Bool)) fun _ => fun i j hij =>
      min_le_min (by exact_mod_cast hij) le_rfl)
    (ae_of_all (Measure.dirac (true : Bool)) fun _ =>
      Tendsto.congr'
        (Filter.eventually_atTop.mpr ⟨1, fun n hn =>
          (min_eq_right (by exact_mod_cast hn : (1:ℝ≥0∞) ≤ (n : ℕ))).symm⟩ :
          (fun _ => (1:ℝ≥0∞)) =ᶠ[atTop] fun n : ℕ => ((n : ℕ) : ℝ≥0∞) ⊓ 1)
        tendsto_const_nhds)
  rwa [hfin] at key

/-! ## DCT 实弹：[0,1] 上 fₙ = xⁿ -/

/-- xⁿ 在 [0,1] 上 a.e. → 0：坏集 ∩ [0,1] ⊆ {1}，零测。 -/
private theorem ae_pow_restrict :
    ∀ᵐ x ∂((volume : Measure ℝ).restrict (Set.Icc (0:ℝ) 1)),
      Tendsto (fun n : ℕ => x ^ n) atTop (𝓝 (0:ℝ)) := by
  rw [ae_iff]
  have hsub : {x : ℝ | ¬Tendsto (fun n : ℕ => x ^ n) atTop (𝓝 (0:ℝ))}
      ∩ Set.Icc (0:ℝ) 1 ⊆ ({1} : Set ℝ) := by
    intro x hx
    simp only [Set.mem_inter_iff, Set.mem_ofPred_eq] at hx
    obtain ⟨hnot, hmem⟩ := hx
    by_contra hc
    have hx1 : x ≠ 1 := fun he => hc (by simp [he])
    exact hnot (tendsto_pow_atTop_nhds_zero_of_lt_one hmem.1
      (lt_of_le_of_ne hmem.2 hx1))
  have hnull : ((volume : Measure ℝ).restrict (Set.Icc (0:ℝ) 1))
      {x : ℝ | ¬Tendsto (fun n : ℕ => x ^ n) atTop (𝓝 (0:ℝ))} = 0 := by
    rw [Measure.restrict_apply' measurableSet_Icc]
    exact measure_mono_null hsub (Set.Finite.measure_zero (Set.finite_singleton 1) _)
  exact hnull

/-- DCT（严书 3.2.5 的机器版）：|xⁿ| ≤ 1 可积、a.e. → 0 ⟹ ∫ xⁿ → 0。
四件套：AEStronglyMeasurable、可积控制、a.e. 控制、a.e. 极限。 -/
example : Tendsto (fun n => ∫ x : ℝ in Set.Icc (0:ℝ) 1, x ^ n ∂volume)
    atTop (𝓝 0) := by
  have hfininst : IsFiniteMeasure ((volume : Measure ℝ).restrict (Set.Icc (0:ℝ) 1)) :=
    isFiniteMeasure_restrict.mpr (by
      rw [Real.volume_Icc]
      simp)
  simpa using tendsto_integral_of_dominated_convergence (fun _ => (1:ℝ))
    (fun n => ⟨fun x => x ^ n, (continuous_pow n).stronglyMeasurable, by simp⟩)
    (integrable_const 1)
    (fun n => by
      filter_upwards [ae_restrict_mem measurableSet_Icc] with x hx
      rw [Real.norm_eq_abs, abs_of_nonneg (pow_nonneg hx.1 n)]
      exact (pow_le_pow_left₀ hx.1 hx.2 n).trans_eq (one_pow n))
    ae_pow_restrict
