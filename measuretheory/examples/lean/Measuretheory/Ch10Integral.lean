import Mathlib.MeasureTheory.Integral.Lebesgue.Add
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic

/-!
# 第 10 章 积分的构造与基本性质（Lean）

严书 §3.1。mathlib 的三步构造封箱：`lintegral`（ℝ≥0∞ 值，
Integral/Lebesgue/Basic.lean:48，irreducible_def——定义体不透明，
一切性质走 API）+ 实值 Bochner 积分 `integral`（第 16 章主角，
`#check` 先正名）。

本文件对齐：第一步的 SimpleFunc 接口、第二步的线性/单调/a.e. 无关、
Markov 不等式的**手作**证明（lintegral_indicator + lintegral_mono
两行内核）、以及 [0,1] 上的常值积分实弹。
-/

open MeasureTheory
open scoped ENNReal

/-! ## 锚点正名 -/

#check @MeasureTheory.lintegral
#check @MeasureTheory.SimpleFunc.lintegral_eq_lintegral
#check @MeasureTheory.integral

variable {α : Type*} [MeasurableSpace α] {μ : Measure α}
variable {f g : α → ℝ≥0∞}

/-! ## 第一步与第二步的接口 -/

/-- S⁺ 的常值元：∫ c dμ = c·μ(Ω)（0·∞ = 0 约定已封箱）。 -/
example (c : ℝ≥0∞) : ∫⁻ _, c ∂μ = c * μ Set.univ :=
  lintegral_const c

/-- 非负可加。注：本版 mathlib 已把 `lintegral_add`（双边可测）降级为
内部件 `lintegral_add_aux`，主推 `lintegral_add_left`——只需左边可测。 -/
example (hf : Measurable f) (g : α → ℝ≥0∞) :
    ∫⁻ x, f x + g x ∂μ = ∫⁻ x, f x ∂μ + ∫⁻ x, g x ∂μ :=
  lintegral_add_left hf g

/-- 单调性：逐点序直接过积分。 -/
example (hfg : f ≤ g) : ∫⁻ x, f x ∂μ ≤ ∫⁻ x, g x ∂μ :=
  lintegral_mono hfg

/-- a.e. 无关：积分对零测集失明。 -/
example (h : f =ᵐ[μ] g) : ∫⁻ x, f x ∂μ = ∫⁻ x, g x ∂μ :=
  lintegral_congr_ae h

/-! ## Markov 不等式：两行内核的手作 -/

/-- Markov：a·μ([f ≥ a]) ≤ ∫⁻ f。
内核：指示函数 a·I_{[f≥a]} ≤ f 逐点成立（成员处 a·1 ≤ f，
非成员处 0 ≤ f），`lintegral_indicator` 把左边精确积分出来
（restrict + 常值），`lintegral_mono` 收口。 -/
example (hf : Measurable f) (a : ℝ≥0∞) :
    a * μ {x | a ≤ f x} ≤ ∫⁻ x, f x ∂μ := by
  have hset : MeasurableSet {x | a ≤ f x} := by
    have hpre : {x : α | a ≤ f x} = f ⁻¹' Set.Ici a := rfl
    rw [hpre]
    exact hf measurableSet_Ici
  have hpt : ∀ x, {y | a ≤ f y}.indicator (fun _ => a) x ≤ f x := by
    intro x
    by_cases hx : x ∈ {y | a ≤ f y}
    · simp only [Set.indicator_of_mem hx]
      exact hx
    · simp [hx]
  calc a * μ {x | a ≤ f x}
      = ∫⁻ x, {y | a ≤ f y}.indicator (fun _ => a) x ∂μ := by
        rw [lintegral_indicator hset (fun _ => a), lintegral_const,
          Measure.restrict_apply_univ]
    _ ≤ ∫⁻ x, f x ∂μ := lintegral_mono hpt

/-! ## 实弹：[0,1] 上的常值积分 -/

example : ∫⁻ _, (1:ℝ≥0∞) ∂((volume : Measure ℝ).restrict (Set.Ioc (0:ℝ) 1)) = 1 := by
  rw [lintegral_const, Measure.restrict_apply_univ, Real.volume_Ioc]
  simp
