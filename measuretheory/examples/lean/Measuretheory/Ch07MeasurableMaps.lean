import Mathlib.MeasureTheory.Constructions.BorelSpace.Real
import Mathlib.MeasureTheory.Measure.Map
import Mathlib.MeasureTheory.Measure.Dirac

/-!
# 第 07 章 可测映射（Lean）

严书 §2.1。机器件对齐三件事：

* σ(f) 的显式公式与生成系版本（`comap_eq_generateFrom` /
  `comap_generateFrom`，MeasurableSpace/Basic.lean）；
* 在生成系上检查可测性（`measurable_generateFrom`，命题 2.1.3）；
* 复合可测（`Measurable.comp`，习题 2.1.2）与像测度（`Measure.map`）。

实值情形五等价条件（严书 2.1.4）用 `Real.borel_eq_generateFrom_Iic_rat`
与 `Real.borel_eq_generateFrom_Iio_rat` 两个生成等式各自直接收割——
这正是严书证明的路线（"σ(C₁) = ℬ，由 2.1.3 即得"）。

实施记要（两坑）：生成族的成员关系（⋃ + 单元素集）要先用
`simp only [Set.mem_iUnion, Set.mem_singleton_iff]` 剥开再解构，
`rintro ⟨r, rfl⟩` 直接上会在 Membership 外壳上翻车；generateFrom
实例与 ℝ 的环境实例不定义相等，须两步换算
（`BorelSpace.measurable_eq` + 生成等式）后再 `exact`。
-/

open MeasureTheory
open scoped ENNReal

/-! ## σ(f)：诱导 σ-代数 -/

section Comap

variable {α β : Type*} [MeasurableSpace β]

/-- σ(f) 的公式（严书 2.1.1 的概念）：由可测集原像生成。
`m.comap f` 就是"使 f 可测的最小 σ-代数"。 -/
example (m : MeasurableSpace β) (f : α → β) :
    m.comap f = MeasurableSpace.generateFrom
      {t | ∃ s, MeasurableSet[m] s ∧ f ⁻¹' s = t} :=
  MeasurableSpace.comap_eq_generateFrom m f

/-- 习题 2.1.1 的机器版：生成系的原像生成原像的 σ-代数。 -/
example (f : α → β) (s : Set (Set β)) :
    (MeasurableSpace.generateFrom s).comap f
      = MeasurableSpace.generateFrom ((Set.preimage f) '' s) :=
  MeasurableSpace.comap_generateFrom

end Comap

/-- 命题 2.1.3 的机器版：可测性只需对生成系检查。
（注意 generateFrom 造的是**陪域** σ-代数；方括号实例语法只改值域侧，
这里用 @-显式形式。） -/
example {γ : Type*} [MeasurableSpace γ] {β : Type*}
    (s : Set (Set β)) (f : γ → β)
    (h : ∀ t ∈ s, MeasurableSet (f ⁻¹' t)) :
    @Measurable γ β _ (MeasurableSpace.generateFrom s) f :=
  measurable_generateFrom h

/-! ## 复合与像测度 -/

/-- 习题 2.1.2：可测映射的复合可测。 -/
example {α β γ : Type*} [MeasurableSpace α] [MeasurableSpace β]
    [MeasurableSpace γ] {f : α → β} {g : β → γ}
    (hf : Measurable f) (hg : Measurable g) : Measurable (g ∘ f) :=
  hg.comp hf

/-- 连续 ⟹ Borel 可测（习题 2.1.5 的前半：开集原像开、开集可测）。 -/
example : Measurable fun x : ℝ => x + 1 := by
  exact (continuous_id.add continuous_const).measurable

/-- 像测度（分布）：μ ∘ f⁻¹。狄拉克质量在奇偶映射下搬到 {1}。 -/
example :
    Measure.map (fun n : ℕ => n % 2) (Measure.dirac (3 : ℕ)) {1} = 1 := by
  have hf : Measurable (fun n : ℕ => n % 2) := fun s _ =>
    Set.Countable.measurableSet (Set.to_countable _)
  have hmem : (3 : ℕ) ∈ (fun n : ℕ => n % 2) ⁻¹' {1} := by
    simp [Set.mem_preimage]
  rw [Measure.map_apply hf (Set.Countable.measurableSet (Set.to_countable _)),
    Measure.dirac_apply_of_mem hmem]

/-! ## 实值情形：五等价检查（严书 2.1.4） -/

/-- 生成等式的两步换算：generateFrom(有理 Iic) = ℝ 的环境实例。
（直接 rw 生成等式会留下 `borel ℝ` 与环境实例的定义不相等残局。） -/
private theorem gen_Iic_eq :
    MeasurableSpace.generateFrom (⋃ a : ℚ, {Set.Iic (a : ℝ)})
      = (inferInstance : MeasurableSpace ℝ) :=
  (BorelSpace.measurable_eq.trans Real.borel_eq_generateFrom_Iic_rat).symm

private theorem gen_Iio_eq :
    MeasurableSpace.generateFrom (⋃ a : ℚ, {Set.Iio (a : ℝ)})
      = (inferInstance : MeasurableSpace ℝ) :=
  (BorelSpace.measurable_eq.trans Real.borel_eq_generateFrom_Iio_rat).symm

/-- (2) ⟹ 可测：[f ≤ a] 型原像全可测 ⟹ f Borel 可测。 -/
example {α : Type*} [MeasurableSpace α] {f : α → ℝ}
    (h : ∀ a : ℝ, MeasurableSet {ω | f ω ≤ a}) : Measurable f := by
  have hgen : @Measurable α ℝ _
      (MeasurableSpace.generateFrom (⋃ a : ℚ, {Set.Iic (a : ℝ)})) f :=
    measurable_generateFrom (by
      intro t ht
      simp only [Set.mem_iUnion, Set.mem_singleton_iff] at ht
      obtain ⟨r, rfl⟩ := ht
      convert h (r : ℝ) using 1
      ext ω
      simp [Set.mem_preimage, Set.mem_Iic])
  rw [gen_Iic_eq] at hgen
  exact hgen

/-- (1) ⟹ 可测：[f < a] 型原像全可测 ⟹ f Borel 可测（严格不等号版，
严书由 [f ≤ a] = ⋂ₙ [f < a + 1/n] 与 [f < a] = ⋃ₙ [f ≤ a − 1/n]
打通两组；机器侧由两个独立的生成等式各自直达）。 -/
example {α : Type*} [MeasurableSpace α] {f : α → ℝ}
    (h : ∀ a : ℝ, MeasurableSet {ω | f ω < a}) : Measurable f := by
  have hgen : @Measurable α ℝ _
      (MeasurableSpace.generateFrom (⋃ a : ℚ, {Set.Iio (a : ℝ)})) f :=
    measurable_generateFrom (by
      intro t ht
      simp only [Set.mem_iUnion, Set.mem_singleton_iff] at ht
      obtain ⟨r, rfl⟩ := ht
      convert h (r : ℝ) using 1
      ext ω
      simp [Set.mem_preimage, Set.mem_Iio])
  rw [gen_Iio_eq] at hgen
  exact hgen

/-- 严格与非严格的补转换（严书 2.1.4 证明内部）：[f > a] = ([f ≤ a])ᶜ。
可测函数侧直接用预像：{f > a} = f⁻¹'(Ioi a)。 -/
example {α : Type*} [MeasurableSpace α] {f : α → ℝ} (a : ℝ)
    (h : Measurable f) : MeasurableSet {ω | f ω > a} := by
  have heq : {ω : α | f ω > a} = f ⁻¹' (Set.Ioi a) := by
    ext ω
    simp [Set.mem_Ioi]
  rw [heq]
  exact h measurableSet_Ioi
