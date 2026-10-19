import Mathlib.MeasureTheory.Constructions.BorelSpace.Real

/-!
# 第 08 章 函数形式的单调类定理（Lean）

严书 §2.2。mathlib 没有直接打包"函数形式单调类定理"，但它的集合层
引擎是现成的：`MeasurableSpace.induction_on_inter`（MeasureTheory/
PiSystem.lean:692，谓词式 π-λ 定理，DynkinSystem 归纳实现）。

本文件三件事：

1. 用 `induction_on_inter` 完整重放经典应用：ℝ 上两个有限测度在
   有理射线 π-系上相等 ⟹ 处处相等（谓词 C t := μ t = ν t）；
2. 严书 2.2.3 注的"垫高技巧"机器版：锥 + 差封闭 ⟹ 加法封闭；
3. 格运算公式 f ∨ g = (f + g + |f − g|)/2 的可测性（函数格封闭
   的代数内核；新 mathlib 已把这类目标交给 `fun_prop`）。

实施记要（坑）：`⋃ a : ℚ, {Iic ↑a}` 的成员关系必须先
`simp only [Set.mem_iUnion, Set.mem_singleton_iff]` 剥开再解构，
对局部 `set` 定义的集合族此招失效（simp 看不穿局部定义）——
直接用字面表达式最稳。
-/

open MeasureTheory
open scoped ENNReal

/-! ## 1. 引擎点火：谓词式 π-λ 的完整重放 -/

/-- 集合版单调类引擎的实弹（第 02 章定理的机器对应物）：有限测度
在有理射线 π-系 {Iic r : r ∈ ℚ} 上相等 ⟹ 在全 Borel σ-代数上相等。

谓词 C t := μ t = ν t；检查单：∅（零测）、基本元（假设）、
补（有限性垫付 μ tᶜ = μ Ω − μ t）、可数不交并（可数可加）。 -/
example (μ ν : Measure ℝ) (hμfin : μ Set.univ ≠ ∞) (hνfin : ν Set.univ ≠ ∞)
    (h : ∀ r : ℚ, μ (Set.Iic (r : ℝ)) = ν (Set.Iic (r : ℝ))) : μ = ν := by
  -- π-系：两支有理射线的交仍是（某支）有理射线
  have hpi : IsPiSystem (⋃ a : ℚ, {Set.Iic (a : ℝ)}) := by
    rintro s hs t ht -
    simp only [Set.mem_iUnion, Set.mem_singleton_iff] at hs ht
    obtain ⟨a, rfl⟩ := hs
    obtain ⟨b, rfl⟩ := ht
    rcases le_total (a : ℝ) b with hab | hab
    · refine Set.mem_iUnion.2 ⟨a, ?_⟩
      simp only [Set.mem_singleton_iff]
      rw [Set.Iic_inter_Iic, min_eq_left hab]
    · refine Set.mem_iUnion.2 ⟨b, ?_⟩
      simp only [Set.mem_singleton_iff]
      rw [Set.Iic_inter_Iic, min_eq_right hab]
  -- 环境实例 = generateFrom（两步换算：实例 = borel = generateFrom）
  have hEq : (inferInstance : MeasurableSpace ℝ)
      = MeasurableSpace.generateFrom (⋃ a : ℚ, {Set.Iic (a : ℝ)}) :=
    BorelSpace.measurable_eq.trans Real.borel_eq_generateFrom_Iic_rat
  -- 有限性代数：全空间有限 ⟹ 一切集合测度有限
  have hμne : ∀ t : Set ℝ, μ t ≠ ∞ := fun t hcon =>
    hμfin (le_antisymm le_top (hcon.ge.trans (measure_mono (Set.subset_univ t))))
  have hνne : ∀ t : Set ℝ, ν t ≠ ∞ := fun t hcon =>
    hνfin (le_antisymm le_top (hcon.ge.trans (measure_mono (Set.subset_univ t))))
  -- 总质量相等（ⓘ 补集一步需要 μ Ω = ν Ω：射线上取极限，下方连续）
  have huniv : μ Set.univ = ν Set.univ := by
    have hcover : (⋃ n : ℕ, Set.Iic (((n : ℚ) : ℝ))) = Set.univ := by
      ext x
      simp only [Set.mem_iUnion, Set.mem_univ, iff_true]
      obtain ⟨n, hn⟩ := exists_nat_gt x
      exact ⟨n, Set.mem_Iic.2 (by push_cast; exact le_of_lt hn)⟩
    have hmonoS : Monotone fun n : ℕ => (Set.Iic (((n : ℚ) : ℝ))) :=
      fun a b hab => Set.Iic_subset_Iic.mpr (by push_cast; exact_mod_cast hab)
    rw [← hcover, hmonoS.measure_iUnion, hmonoS.measure_iUnion]
    exact iSup_congr fun n => h (n : ℚ)
  refine Measure.ext fun t ht =>
    MeasurableSpace.induction_on_inter (C := fun t _ => μ t = ν t)
      hEq hpi ?_ ?_ ?_ ?_ t ht
  · rw [measure_empty, measure_empty]
  · rintro s hs
    simp only [Set.mem_iUnion, Set.mem_singleton_iff] at hs
    obtain ⟨r, rfl⟩ := hs
    exact h r
  · intro s hms ih
    rw [measure_compl hms (hμne s), measure_compl hms (hνne s), huniv, ih]
  · intro f hdf hmf ihf
    rw [measure_iUnion hdf hmf, measure_iUnion hdf hmf]
    simp only [ihf]

/-! ## 2. λ-族的代数内核（严书 2.2.3 注） -/

/-- 垫高技巧（严书 2.2.3 注的机器版）：含常值 1 的非负函数族若
对非负数乘与"优函数减劣函数"封闭，则对加法封闭。证明即严书
原行文：取常量 C ≥ f + g，则 f + g = C − [(C − f) − g]，
三次用差封闭。 -/
example {α : Type*} {C : ℝ} (H : (α → ℝ) → Prop)
    (hone : H fun _ => 1)
    (hsmul : ∀ (c : ℝ) (f : α → ℝ), 0 ≤ c → H f → H fun ω => c * f ω)
    (hdiff : ∀ f g : α → ℝ, (∀ ω, g ω ≤ f ω) → (∀ ω, (0:ℝ) ≤ f ω - g ω) →
      H f → H g → H fun ω => f ω - g ω)
    (f g : α → ℝ) (hf : H f) (hg : H g)
    (hf0 : ∀ ω, (0:ℝ) ≤ f ω) (hg0 : ∀ ω, (0:ℝ) ≤ g ω)
    (hC : (0:ℝ) < C) (hCf : ∀ ω, f ω + g ω ≤ C) :
    H fun ω => f ω + g ω := by
  have hC1 : H fun _ => C * (1:ℝ) := hsmul C (fun _ => (1:ℝ)) hC.le hone
  -- C − f（第一次差封闭；序关系全部线性可解）
  have hCf' : H fun ω => C * (1:ℝ) - f ω :=
    hdiff (fun _ => C * (1:ℝ)) f
      (fun ω => by linarith [hCf ω, hg0 ω])
      (fun ω => by linarith [hCf ω, hf0 ω, hg0 ω]) hC1 hf
  -- (C − f) − g（第二次）
  have hCf2 : H fun ω => (C * (1:ℝ) - f ω) - g ω :=
    hdiff (fun ω => C * (1:ℝ) - f ω) g
      (fun ω => by linarith [hCf ω, hg0 ω])
      (fun ω => by linarith [hCf ω, hf0 ω, hg0 ω]) hCf' hg
  -- f + g = C − [(C − f) − g]（第三次）
  have hfin : H fun ω => C * (1:ℝ) - ((C * (1:ℝ) - f ω) - g ω) :=
    hdiff (fun _ => C * (1:ℝ)) (fun ω => (C * (1:ℝ) - f ω) - g ω)
      (fun ω => by linarith [hCf ω, hf0 ω, hg0 ω])
      (fun ω => by linarith [hCf ω, hf0 ω, hg0 ω]) hC1 hCf2
  have heq : (fun ω : α => f ω + g ω)
      = fun ω => C * (1:ℝ) - ((C * (1:ℝ) - f ω) - g ω) :=
    funext fun ω => by ring
  rw [heq]
  exact hfin

/-! ## 3. 格运算的代数内核：f ∨ g = (f + g + |f − g|)/2 -/

/-- 严书 2.2.2 证明中"有限上端"的来源公式。可测函数对格运算封闭，
本质是这套初等恒等式 + 连续函数（|·|、线性）保持可测。
新 mathlib 里这类目标通常一行 `fun_prop`。 -/
example {α : Type*} [MeasurableSpace α] (f g : α → ℝ)
    (hf : Measurable f) (hg : Measurable g) :
    Measurable fun ω => max (f ω) (g ω) := by
  have hformula : ∀ ω : α,
      max (f ω) (g ω) = (f ω + g ω + |f ω - g ω|) / 2 := by
    intro ω
    rcases le_total (f ω) (g ω) with h | h
    · rw [max_eq_right h, abs_of_nonpos (by linarith)]
      ring
    · rw [max_eq_left h, abs_of_nonneg (by linarith)]
      ring
  have hrw : (fun ω => max (f ω) (g ω))
      = fun ω => (f ω + g ω + |f ω - g ω|) / 2 :=
    funext fun ω => hformula ω
  rw [hrw]
  fun_prop
