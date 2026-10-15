import Mathlib.MeasureTheory.Function.LpSeminorm.Basic
import Mathlib.MeasureTheory.Function.LpSeminorm.TriangleInequality
import Mathlib.MeasureTheory.Function.LpSpace.Complete
import Mathlib.MeasureTheory.Integral.Lebesgue.Add
import Mathlib.MeasureTheory.Integral.DominatedConvergence
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.MeasureTheory.Measure.Restrict

/-!
# 第 70 章 · 勒贝格积分与 L^p（工科篇 1.4 + 1.7）

《工科泛函分析基础》1.4 节路线的机器化：外测度 → 可测集 → 可测函数 →
切值域的积分定义 → 三大收敛定理 → L^p 空间。

本章 Lean 通道三层：
1. **狄利克雷函数全证**：ℚ 可数 ⟹ 零测 ⟹ D = 0 a.e. ⟹ 积分为 0
   ——书的例 1.4.19（黎曼不可积、勒贝格积分为零）的完整形式化；
2. 示性函数与受控函数进入 L^p（`memLp_indicator_const` / `MemLp.of_le`），
   对应书中勒贝格大小和的示性函数层与截断思想；
3. 收敛定理与完备性的官方锚点巡礼（MCT/Fatou/DCT/Riesz-Fischer/
   Minkowski/Hölder）。

测度论的完整构造（Carathéodory 扩张等）在 mathlib 中是 `MeasureTheory`
层级的数万行工程，本文件只做**应用层**的机器化——工科路线的诚实分工。
-/

open MeasureTheory
open Set
open scoped Classical
open scoped ENNReal

/-- ℚ 作为 ℝ 的子集（`Set.range Rat.cast`）是可数集 ⟹ 勒贝格零测集
（书 1.4.5 + 1.4.11）。 -/
example : volume (Set.range (Rat.cast : ℚ → ℝ)) = 0 :=
  Set.Countable.measure_zero (Set.countable_range _) _

/-- **狄利克雷函数在 [0,1] 上勒贝格积分为零**（书的例 1.4.19）：
黎曼大小和永远差 1 的函数，切值域定义下积分为 0。
证明三步：D ≠ 0 的点集 ⊆ ℚ（可数 ⟹ 零测）⟹ D = 0 a.e. ⟹ 换积分。 -/
theorem dirichlet_integral_zero :
    ∫ x in Icc (0 : ℝ) 1, (if x ∈ Set.range (Rat.cast : ℚ → ℝ) then (1 : ℝ) else 0)
      ∂volume = 0 := by
  have hQ : volume (Set.range (Rat.cast : ℚ → ℝ)) = 0 :=
    Set.Countable.measure_zero (Set.countable_range _) _
  have hsub : {x : ℝ | (if x ∈ Set.range (Rat.cast : ℚ → ℝ) then (1 : ℝ) else 0) ≠ 0}
      ⊆ Set.range (Rat.cast : ℚ → ℝ) := by
    intro x hx
    by_contra hxQ
    exact hx (by rw [if_neg hxQ])
  have hnull : volume
      {x : ℝ | (if x ∈ Set.range (Rat.cast : ℚ → ℝ) then (1 : ℝ) else 0) ≠ 0} = 0 :=
    measure_mono_null hsub hQ
  have h0 : volume.restrict (Icc (0 : ℝ) 1)
      {x : ℝ | (if x ∈ Set.range (Rat.cast : ℚ → ℝ) then (1 : ℝ) else 0) ≠ 0} = 0 := by
    rw [Measure.restrict_apply' measurableSet_Icc]
    exact measure_mono_null Set.inter_subset_left hnull
  have hae : (fun x : ℝ => if x ∈ Set.range (Rat.cast : ℚ → ℝ) then (1 : ℝ) else 0)
      =ᵐ[volume.restrict (Icc (0 : ℝ) 1)] (fun _ => 0) := ae_iff.2 h0
  rw [integral_congr_ae hae]
  simp

/-- 狄利克雷函数勒贝格可积（a.e. 零 + 有界 + 有限测度的组合事实）。 -/
theorem dirichlet_integrable :
    Integrable (fun x : ℝ => if x ∈ Set.range (Rat.cast : ℚ → ℝ) then (1 : ℝ) else 0)
      (volume.restrict (Icc (0 : ℝ) 1)) := by
  have hQ : volume (Set.range (Rat.cast : ℚ → ℝ)) = 0 :=
    Set.Countable.measure_zero (Set.countable_range _) _
  have hsub : {x : ℝ | (if x ∈ Set.range (Rat.cast : ℚ → ℝ) then (1 : ℝ) else 0) ≠ 0}
      ⊆ Set.range (Rat.cast : ℚ → ℝ) := by
    intro x hx
    by_contra hxQ
    exact hx (by rw [if_neg hxQ])
  have hnull : volume
      {x : ℝ | (if x ∈ Set.range (Rat.cast : ℚ → ℝ) then (1 : ℝ) else 0) ≠ 0} = 0 :=
    measure_mono_null hsub hQ
  have h0 : volume.restrict (Icc (0 : ℝ) 1)
      {x : ℝ | (if x ∈ Set.range (Rat.cast : ℚ → ℝ) then (1 : ℝ) else 0) ≠ 0} = 0 := by
    rw [Measure.restrict_apply' measurableSet_Icc]
    exact measure_mono_null Set.inter_subset_left hnull
  have hae : (fun x : ℝ => if x ∈ Set.range (Rat.cast : ℚ → ℝ) then (1 : ℝ) else 0)
      =ᵐ[volume.restrict (Icc (0 : ℝ) 1)] (fun _ => 0) := ae_iff.2 h0
  exact (integrable_congr hae).2
    (integrable_zero (ε' := ℝ) (μ := volume.restrict (Icc (0 : ℝ) 1)))

/-! ## 第二层：示性函数与受控函数进入 L^p -/

section LpExamples

variable {α : Type*} [MeasurableSpace α] {μ : Measure α}

/-- 常函数属于 L^p（有限测度上）——一切积分理论的出发点。 -/
example [IsFiniteMeasure μ] (p : ℝ≥0∞) (c : ℝ) : MemLp (fun _ : α => c) p μ :=
  memLp_const c

/-- 可测集的示性（指示）函数属于 L^p（μ s < ∞ 时）——勒贝格大小和的
基石：大小和正是示性函数的线性组合。 -/
example {s : Set α} (hs : MeasurableSet s) (hμs : μ s ≠ ∞)
    (p : ℝ≥0∞) : MemLp (s.indicator (fun _ => (1 : ℝ))) p μ :=
  memLp_indicator_const p hs 1 (Or.inr hμs)

/-- 受控判据（书 1.4.20 截断思想的一般化）：几乎处处被 L^p 函数控制
且可测的函数自动在 L^p 中——Fatou/DCT 论证中反复使用的成员资格工具。 -/
example {f g : α → ℝ} (hg : MemLp g p μ) (hf : AEStronglyMeasurable f μ)
    (hle : ∀ᵐ x ∂μ, |f x| ≤ |g x|) : MemLp f p μ :=
  MemLp.of_le hg hf (by filter_upwards [hle] with x hx; simpa using hx)

end LpExamples

/-! ## 第三层：收敛定理与完备性的官方锚点 -/

-- 单调收敛定理（书的 Levi 定理 1.4.27）：非负递增可测列的积分取极限
#check @MeasureTheory.lintegral_iSup

-- Fatou 引理（书 1.4.26）：非负函数列积分的下极限控制极限的积分
#check @MeasureTheory.lintegral_liminf_le'

-- 勒贝格控制收敛定理（书 1.4.28）：逐点收敛 + 可积控制 ⟹ 积分收敛
#check @MeasureTheory.tendsto_integral_of_dominated_convergence

-- 积分的绝对连续性（书 1.4.25）在 mathlib 中的形态
#check @MeasureTheory.Measure.AbsolutelyContinuous

-- Minkowski 不等式 = L^p 半范数的三角不等式（书 1.7）
#check @MeasureTheory.eLpNorm_add_le

-- Hölder 不等式（书 1.7）：共轭指数乘积的积分估计
#check @ENNReal.lintegral_mul_le_Lp_mul_Lq

-- Riesz-Fischer 定理：L^p（1 ≤ p）是完备赋范空间——
-- L^p 作为 Banach 空间存在的理由（书第 3 章的底座）
#check @MeasureTheory.Lp.instCompleteSpace

/-- 区间长度公式：勒贝格测度在 Icc 上的值（外测度定义的锚点）。 -/
example (a b : ℝ) : volume (Icc a b) = ENNReal.ofReal (b - a) := Real.volume_Icc
