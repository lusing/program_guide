import Mathlib.MeasureTheory.Measure.Lebesgue.Basic

/-!
# 第 03 章 测度与非负集函数（Lean）

严书 §1.3。测度的定义与基本推论：空集为零、单调性、次可加性、
可数可加（不交版）、下方连续。mathlib 的 `Measure` 即严书的测度
（可取 ∞ 的可数可加集函数），以下逐条对齐。
-/

open MeasureTheory Filter Topology

/-- 空测度：μ ∅ = 0。 -/
example (μ : Measure ℕ) : μ ∅ = 0 := measure_empty

/-- 单调性：s ⊆ t ⟹ μ s ≤ μ t（严书 1.3.3(1)）。 -/
example (μ : Measure ℕ) (s t : Set ℕ) (h : s ⊆ t) : μ s ≤ μ t := measure_mono h

/-- 次可加性（可列版）：μ (∪ sᵢ) ≤ Σ μ sᵢ。 -/
example (μ : Measure ℕ) (s : ℕ → Set ℕ) : μ (⋃ i, s i) ≤ ∑' i, μ (s i) :=
  measure_iUnion_le s

/-- 可数可加性：两两不交集族上取等号（严书 1.3.2 定义的核心条款）。 -/
example (μ : Measure ℕ) (s : ℕ → Set ℕ) (hd : Pairwise (fun i j => Disjoint (s i) (s j)))
    (hm : ∀ i, MeasurableSet (s i)) : μ (⋃ i, s i) = ∑' i, μ (s i) :=
  measure_iUnion hd hm

/-- 次可加性（有限版）。 -/
example (μ : Measure ℕ) (s t : Set ℕ) : μ (s ∪ t) ≤ μ s + μ t := measure_union_le _ _

/-- 下方连续（严书 1.3.3）：单调升列的测度趋于并的测度。
mathlib 的 `Monotone.measure_iUnion` 直接给出 sup 形式。 -/
example (μ : Measure ℕ) (f : ℕ → Set ℕ) (hmono : Monotone f)
    : μ (⋃ i, f i) = ⨆ i, μ (f i) :=
  hmono.measure_iUnion

/-- 上方连续的具象例子：volume (0, 1/n) ↓ 0（首项有限时极限可穿过测度）。 -/
example : Tendsto (fun (n : ℕ) => (volume : Measure ℝ) (Set.Ioo (0 : ℝ) ((n : ℝ)⁻¹)))
    atTop (𝓝 0) := by
  simp only [Real.volume_Ioo, sub_zero]
  have h2 : Tendsto (fun n : ℕ => (n : ℝ)⁻¹) atTop (𝓝 0) :=
    (tendsto_inv_atTop_zero (𝕜 := ℝ)).comp tendsto_natCast_atTop_atTop
  have h3 : Tendsto (fun x : ℝ => ENNReal.ofReal x) (𝓝 0) (𝓝 (ENNReal.ofReal 0)) :=
    ENNReal.continuous_ofReal.tendsto 0
  simpa only [Function.comp_def, ENNReal.ofReal_zero] using h3.comp h2
