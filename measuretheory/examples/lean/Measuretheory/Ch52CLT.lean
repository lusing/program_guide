import Mathlib.Probability.CentralLimitTheorem
import Mathlib.Probability.ProductMeasure
import Mathlib.Probability.Independence.InfinitePi

/-!
# 第 52 章 中心极限定理（Lean）

袁下册第 21 章。mathlib 锚点（`Probability/CentralLimitTheorem.lean`）：
**`ProbabilityTheory.tendstoInDistribution_inv_sqrt_mul_sum_sub`**
（iid CLT 完全体：`MemLp 2` + `iIndepFun` + `IdentDistrib` 三前提
⟹ `(√n)⁻¹ • (ΣXₖ − n𝔼X)` 依分布收敛到 `gaussianReal 0 Var`）。

实弹：**Dé Moivre-Laplace 定理的机器版**——硬币空间（51 章
机器件复用）上的 Bernoulli(1/2) 序列代入 CLT：方差账
Var = 1/4 显式结清（映像到 bern52 的 dirac 折叠），极限户口
`gaussianReal 0 (1/4)` 显式化。
-/

open MeasureTheory ProbabilityTheory Filter
open scoped ENNReal NNReal Topology Function

/-! ## 硬币机器件（51 章同款，本章自含） -/

/-- Bernoulli(1/2)。 -/
noncomputable def bern52 : Measure Bool :=
  (2 : ℝ≥0∞)⁻¹ • (Measure.dirac true + Measure.dirac false)

instance : IsProbabilityMeasure bern52 := by
  constructor
  simp [bern52, Measure.smul_apply, Measure.add_apply, Set.indicator_of_mem,
    ENNReal.inv_two_add_inv_two]

/-- 无穷硬币空间。 -/
noncomputable def coin52 : Measure (ℕ → Bool) := Measure.infinitePi fun _ : ℕ => bern52

instance : IsProbabilityMeasure coin52 := by
  show IsProbabilityMeasure (Measure.infinitePi fun _ : ℕ ↦ bern52)
  infer_instance

lemma coin52_map_eval (i : ℕ) : coin52.map (fun ω ↦ ω i) = bern52 :=
  Measure.infinitePi_map_eval (fun _ : ℕ ↦ bern52) i

/-- 位值函数与位值随机变量。 -/
def bitVal52 : Bool → ℝ := fun b ↦ if b then 1 else 0

def bitAt52 (i : ℕ) (ω : ℕ → Bool) : ℝ := bitVal52 (ω i)

lemma bitVal52_measurable : Measurable bitVal52 := measurable_of_countable _

lemma bitAt52_measurable (i : ℕ) : Measurable (bitAt52 i) :=
  bitVal52_measurable.comp (measurable_pi_apply i)

lemma coin52_iIndep : iIndepFun (fun i ω ↦ ω i) coin52 :=
  (iIndepFun_iff_map_fun_eq_infinitePi_map₀'
    (fun i ↦ (measurable_pi_apply i).aemeasurable)).mpr (by
    have hid : (fun ω : (ℕ → Bool) ↦ fun i ↦ ω i) = id := rfl
    rw [hid, Measure.map_id,
      show (fun i ↦ coin52.map fun ω ↦ ω i) = fun _ : ℕ ↦ bern52 from
        funext fun i ↦ coin52_map_eval i]
    rfl)

lemma bitAt52_iIndep : iIndepFun bitAt52 coin52 :=
  coin52_iIndep.comp (fun _ ↦ bitVal52) fun _ ↦ bitVal52_measurable

lemma bitAt52_ident (i : ℕ) : IdentDistrib (bitAt52 i) (bitAt52 0) coin52 coin52 := by
  refine ⟨(bitAt52_measurable i).aemeasurable, (bitAt52_measurable 0).aemeasurable, ?_⟩
  show coin52.map (bitAt52 i) = coin52.map (bitAt52 0)
  rw [show bitAt52 i = bitVal52 ∘ (fun ω ↦ ω i) from rfl,
    ← Measure.map_map bitVal52_measurable (measurable_pi_apply i), coin52_map_eval i,
    show bitAt52 0 = bitVal52 ∘ (fun ω ↦ ω 0) from rfl,
    ← Measure.map_map bitVal52_measurable (measurable_pi_apply 0), coin52_map_eval 0]

/-! ## 矩账：期望 1/2、二阶矩户口、方差 1/4 -/

lemma bitVal52_integral : ∫ b, bitVal52 b ∂bern52 = 1 / 2 := by
  rw [bern52, integral_smul_measure,
    integral_add_measure (integrable_dirac (by simp [bitVal52]))
      (integrable_dirac (by simp [bitVal52])),
    integral_dirac, integral_dirac]
  simp [bitVal52]

lemma bitAt52_integral : ∫ ω, bitAt52 0 ω ∂coin52 = 1 / 2 := by
  rw [← bitVal52_integral, ← coin52_map_eval 0,
    integral_map (measurable_pi_apply 0).aemeasurable bitVal52_measurable.aestronglyMeasurable]
  rfl

/-- 二阶矩户口（CLT 的 MemLp 2 前提）。 -/
lemma bitAt52_memLp2 : MemLp (bitAt52 0) 2 coin52 :=
  MemLp.of_bound (bitAt52_measurable 0).aestronglyMeasurable 1
    (Filter.Eventually.of_forall fun ω ↦ by
      simp only [bitAt52, bitVal52]
      split_ifs <;> simp)

/-- 中心化平方的可积性（MemLp.of_bound 路线，绕开 dirac enorm 坑）。 -/
lemma bitVal52_sq_integrable : Integrable (fun b ↦ (bitVal52 b - 1 / 2) ^ 2) bern52 := by
  rw [← memLp_one_iff_integrable]
  exact MemLp.of_bound
    (((bitVal52_measurable.sub measurable_const).pow measurable_const).aestronglyMeasurable) 1
    (Filter.Eventually.of_forall fun b ↦ by
      show ‖(bitVal52 b - 1 / 2) ^ 2‖ ≤ 1
      simp only [bitVal52]
      split_ifs <;> simp <;> norm_num)

/-- 中心化平方的映像账：∫ (bitVal b − 1/2)² d bern52 = 1/4
（integral_fintype + 两点求和直算）。 -/
lemma bitVal52_sq_integral : ∫ b, (bitVal52 b - 1 / 2) ^ 2 ∂bern52 = 1 / 4 := by
  rw [integral_fintype bitVal52_sq_integrable]
  have hb : ∀ b : Bool, bern52.real {b} = 1 / 2 := by
    intro b; cases b <;>
      simp [bern52, Measure.real, Measure.smul_apply, Measure.add_apply]
  have huniv : (Finset.univ : Finset Bool) = {false, true} := by decide
  rw [huniv, Finset.sum_insert (by simp), Finset.sum_singleton, hb false, hb true]
  simp [bitVal52]
  norm_num

/-- **方差账**：Var = E(X−μ)² = 1/4（variance_eq_integral +
映像折叠）。 -/
lemma bitAt52_variance : Var[bitAt52 0; coin52] = 1 / 4 := by
  rw [variance_eq_integral (bitAt52_measurable 0).aemeasurable, bitAt52_integral]
  have e1 : ∫ ω, (bitAt52 0 ω - 1 / 2) ^ 2 ∂coin52
      = ∫ b, (bitVal52 b - 1 / 2) ^ 2 ∂bern52 := by
    rw [← coin52_map_eval 0,
      integral_map (measurable_pi_apply 0).aemeasurable
        (((bitVal52_measurable.sub measurable_const).pow measurable_const).aestronglyMeasurable)]
    rfl
  rw [e1, bitVal52_sq_integral]

/-! ## 旗舰：Dé Moivre-Laplace 机器版 -/

/-- **Dé Moivre-Laplace 中心极限定理**：Bernoulli(1/2) 位值和的
标准化 (√n)⁻¹(Sₙ − n/2) 依分布收敛到 N(0, 1/4)——mathlib CLT
在硬币空间上的完整实例化（iid 机器件 + 方差账全显式）。 -/
theorem deMoivreLaplace :
    TendstoInDistribution
      (fun (n : ℕ) ω ↦ (√n)⁻¹ * (∑ k ∈ Finset.range n, bitAt52 k ω - n * (1 / 2 : ℝ)))
      atTop id (fun _ ↦ coin52) (gaussianReal 0 (1 / 4 : ℝ≥0)) := by
  have hv : (Var[bitAt52 0; coin52]).toNNReal = (1 / 4 : ℝ≥0) := by
    rw [bitAt52_variance]
    ext
    rw [Real.coe_toNNReal _ (by norm_num)]
    norm_num
  have hY : HasLaw id (gaussianReal 0 (Var[bitAt52 0; coin52]).toNNReal)
      (gaussianReal 0 (Var[bitAt52 0; coin52]).toNNReal) :=
    ⟨aemeasurable_id, Measure.map_id⟩
  have h := tendstoInDistribution_inv_sqrt_mul_sum_sub (X := bitAt52) (Y := id)
    (P := coin52) (P' := gaussianReal 0 (Var[bitAt52 0; coin52]).toNNReal)
    hY bitAt52_memLp2 bitAt52_iIndep bitAt52_ident
  rw [bitAt52_integral, hv] at h
  exact h

/-! ## 锚点正名 -/

#check @ProbabilityTheory.tendstoInDistribution_inv_sqrt_mul_sum_sub
#check @TendstoInDistribution
#check @ProbabilityTheory.HasLaw
#check @ProbabilityTheory.gaussianReal
