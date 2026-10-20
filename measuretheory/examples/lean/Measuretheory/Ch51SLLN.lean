import Mathlib.Probability.StrongLaw
import Mathlib.Probability.ProductMeasure
import Mathlib.Probability.Independence.InfinitePi

/-!
# 第 51 章 强大数定律（Lean）

袁下册第 20 章。mathlib 锚点（`Probability/StrongLaw.lean`）：
**`ProbabilityTheory.strong_law_ae`**（Etemadi 版——只需两两
独立 + 同分布 + 可积，Banach 空间值）与 `strong_law_Lp`。

旗舰实弹：**Borel 正规数定理的二进制版全机器证**——硬币空间
（20 章 `infinitePi` 工程）上，坐标独立性由
`iIndepFun_iff_map_fun_eq_infinitePi_map₀'` 反向收割
（`Measure.infinitePi_map_eval` 给边际账），SLLN 实例化
给出频率 → 1/2 a.s.；L¹ 版由 `strong_law_Lp` 免费再收一份。
-/

open MeasureTheory ProbabilityTheory Filter
open scoped ENNReal NNReal Topology Function

/-! ## 硬币空间与坐标独立性 -/

/-- Bernoulli(1/2)：½·(δtrue + δfalse)。 -/
noncomputable def bern51 : Measure Bool :=
  (2 : ℝ≥0∞)⁻¹ • (Measure.dirac true + Measure.dirac false)

instance : IsProbabilityMeasure bern51 := by
  constructor
  simp [bern51, Measure.smul_apply, Measure.add_apply, Set.indicator_of_mem,
    ENNReal.inv_two_add_inv_two]

/-- 无穷次均匀硬币：Bool^ℕ 上的无穷乘积。 -/
noncomputable def coin51 : Measure (ℕ → Bool) := Measure.infinitePi fun _ : ℕ => bern51

instance : IsProbabilityMeasure coin51 := by
  show IsProbabilityMeasure (Measure.infinitePi fun _ : ℕ ↦ bern51)
  infer_instance

/-- 每个坐标投影的边际 = bern51（51.9 链条第一环）。 -/
lemma coin51_map_eval (i : ℕ) : coin51.map (fun ω ↦ ω i) = bern51 :=
  Measure.infinitePi_map_eval (fun _ : ℕ ↦ bern51) i

/-- 坐标联合分布 = 边际的无穷乘积（iid 的机器内核：
联合 = 乘积 ⟺ 独立，`iIndepFun_iff_map_fun_eq_infinitePi_map₀'`
的右端在此验证）。 -/
lemma coin51_map_joint :
    coin51.map (fun ω i ↦ ω i) = Measure.infinitePi fun i ↦ coin51.map fun ω ↦ ω i := by
  have hid : (fun ω : (ℕ → Bool) ↦ fun i ↦ ω i) = id := rfl
  rw [hid, Measure.map_id,
    show (fun i ↦ coin51.map fun ω ↦ ω i) = fun _ : ℕ ↦ bern51 from
      funext fun i ↦ coin51_map_eval i]
  rfl

/-- 硬币各位相互独立（iIndepFun 机器件，构造定理的坐标版）。 -/
lemma coin51_iIndep : iIndepFun (fun i ω ↦ ω i) coin51 :=
  (iIndepFun_iff_map_fun_eq_infinitePi_map₀'
    (fun i ↦ (measurable_pi_apply i).aemeasurable)).mpr coin51_map_joint

/-! ## 位值随机变量 -/

/-- 位值函数：true ↦ 1, false ↦ 0。 -/
def bitVal : Bool → ℝ := fun b ↦ if b then 1 else 0

/-- 第 i 位的位值随机变量。 -/
def bitAt (i : ℕ) (ω : ℕ → Bool) : ℝ := bitVal (ω i)

lemma bitVal_measurable : Measurable bitVal := measurable_of_countable _

lemma bitAt_measurable (i : ℕ) : Measurable (bitAt i) :=
  bitVal_measurable.comp (measurable_pi_apply i)

/-- 位值列两两独立（iIndepFun 的复合保持 + 退化）。 -/
lemma bitAt_pairwise : Pairwise ((· ⟂ᵢ[coin51] ·) on bitAt) := by
  intro i j hij
  exact (coin51_iIndep.comp (fun _ ↦ bitVal) fun _ ↦ bitVal_measurable).indepFun hij

/-- 位值列同分布（每个坐标的映像都过 bern51）。 -/
lemma bitAt_ident (i : ℕ) : IdentDistrib (bitAt i) (bitAt 0) coin51 coin51 := by
  refine ⟨(bitAt_measurable i).aemeasurable, (bitAt_measurable 0).aemeasurable, ?_⟩
  show coin51.map (bitAt i) = coin51.map (bitAt 0)
  rw [show bitAt i = bitVal ∘ (fun ω ↦ ω i) from rfl,
    ← Measure.map_map bitVal_measurable (measurable_pi_apply i), coin51_map_eval i,
    show bitAt 0 = bitVal ∘ (fun ω ↦ ω 0) from rfl,
    ← Measure.map_map bitVal_measurable (measurable_pi_apply 0), coin51_map_eval 0]

/-! ## 期望账与可积性 -/

/-- 位值的期望账：∫ bitVal d bern51 = 1/2（dirac 折叠 + 标量乘）。 -/
lemma bitVal_integral : ∫ b, bitVal b ∂bern51 = 1 / 2 := by
  rw [bern51, integral_smul_measure,
    integral_add_measure (integrable_dirac (by simp [bitVal]))
      (integrable_dirac (by simp [bitVal])),
    integral_dirac, integral_dirac]
  simp [bitVal]

/-- E[第 0 位] = 1/2（映像到 bern51 结账）。 -/
lemma bitAt_integral : ∫ ω, bitAt 0 ω ∂coin51 = 1 / 2 := by
  rw [← bitVal_integral, ← coin51_map_eval 0,
    integral_map (measurable_pi_apply 0).aemeasurable bitVal_measurable.aestronglyMeasurable]
  rfl

/-- 位值可积（有界 ⟹ MemLp ⟹ Integrable，三行内核）。 -/
lemma bitAt_integrable : Integrable (bitAt 0) coin51 := by
  rw [← memLp_one_iff_integrable]
  exact MemLp.of_bound (bitAt_measurable 0).aestronglyMeasurable 1
    (Filter.Eventually.of_forall fun ω ↦ by
      simp only [bitAt, bitVal]
      split_ifs <;> simp)

/-! ## 旗舰：Borel 正规数定理（二进制版） -/

/-- **Borel 正规数定理（二进制）**：均匀硬币位值的频率几乎必然
收敛到 1/2——`strong_law_ae`（Etemadi 版，只需两两独立）在
硬币空间上的完整实例化。1909 年概率论第一个强大数定律的
机器原文。 -/
theorem normal_binary :
    ∀ᵐ ω ∂coin51, Tendsto
      (fun n : ℕ ↦ (n : ℝ)⁻¹ • ∑ i ∈ Finset.range n, bitAt i ω)
      atTop (𝓝 (1 / 2 : ℝ)) := by
  have h := strong_law_ae bitAt bitAt_integrable bitAt_pairwise bitAt_ident
  rwa [bitAt_integral] at h

/-- L¹ 版附赠：频率列依 L¹ 收敛到 1/2（`strong_law_Lp`，p = 1）——
同一套 iid 机器件，多收一份 Lᵖ 收敛账。 -/
theorem normal_binary_L1 :
    Tendsto (fun n : ℕ ↦ eLpNorm
      (fun ω ↦ (n : ℝ)⁻¹ • ∑ i ∈ Finset.range n, bitAt i ω - (1 / 2 : ℝ)) 1 coin51)
      atTop (𝓝 0) := by
  have hmem : MemLp (bitAt 0) 1 coin51 :=
    MemLp.of_bound (bitAt_measurable 0).aestronglyMeasurable 1
      (Filter.Eventually.of_forall fun ω ↦ by
        simp only [bitAt, bitVal]
        split_ifs <;> simp)
  have h := strong_law_Lp (p := 1) le_rfl ENNReal.one_ne_top bitAt hmem
    bitAt_pairwise bitAt_ident
  rwa [bitAt_integral] at h

/-! ## 锚点正名 -/

#check @ProbabilityTheory.strong_law_ae
#check @ProbabilityTheory.strong_law_Lp
#check @Measure.infinitePi_map_eval
#check @iIndepFun_iff_map_fun_eq_infinitePi_map₀'
