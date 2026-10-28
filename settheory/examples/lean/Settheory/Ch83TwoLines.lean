import Mathlib.Order.Filter.Ultrafilter.Basic
import Mathlib.ModelTheory.Ultraproducts

/-!
# 第 83 章 · 非标准实数直线与苏斯林直线

锚点：超滤子的二分律（le_cofinite_or_eq_pure）、非平凡超滤子的存在
（exists_ultrafilter_of_finite_inter_nonempty 应用于余有限集族）、
mathlib 的超积与 Łoś 定理（Ultraproduct.sentence_realize）。
主超滤超幂的退化与超实数构造留在正文；有限影子在其余六通道。
-/

namespace Settheory.Ch83

open Filter Ultrafilter FirstOrder

/-- 二分律：任何超滤子要么延伸余有限滤子（非平凡方向），
要么是某一点的主超滤。 -/
example (F : Ultrafilter ℕ) :
    (F : Filter ℕ) ≤ cofinite ∨ ∃ a : ℕ, F = pure a :=
  F.le_cofinite_or_eq_pure

/-- 非平凡超滤子存在（选择公理下）：余有限集族对有限交封闭且非空，
扩张成超滤子；它含每个 {n}ᶜ，因此不含任何单点集。 -/
theorem exists_nonprincipal : ∃ F : Ultrafilter ℕ, ∀ n : ℕ, {n} ∉ F.sets := by
  obtain ⟨F, hF⟩ := exists_ultrafilter_of_finite_inter_nonempty
      {A : Set ℕ | A.compl.Finite} (by
    intro T hT
    have hfin : (⋃ A ∈ (↑T : Set (Set ℕ)), Aᶜ).Finite := by
      refine Set.Finite.biUnion (Finset.finite_toSet T) fun A hA => ?_
      exact hT (Finset.mem_coe.2 hA)
    have heq : (⋂₀ (↑T : Set (Set ℕ))) = (⋃ A ∈ (↑T : Set (Set ℕ)), Aᶜ)ᶜ := by
      ext x
      simp only [Set.mem_sInter, Set.mem_compl_iff, Set.mem_iUnion, not_exists, not_not]
    rw [heq]
    exact hfin.infinite_compl.nonempty)
  refine ⟨F, fun n hn => ?_⟩
  have hcof : {n}ᶜ ∈ F.sets := by
    refine hF ?_
    have hmem : ({n}ᶜ : Set ℕ).compl.Finite := by
      have hcc2 : ({n}ᶜ : Set ℕ).compl = {n} := compl_compl _
      rw [hcc2]
      simp
    exact hmem
  have hbot : ({n} ∩ ({n}ᶜ : Set ℕ)) ∈ F.sets := F.inter_mem hn hcof
  have hempty : (∅ : Set ℕ) ∈ F.sets := by
    simpa only [Set.inter_compl_self] using hbot
  exact absurd hempty (fun h => (F.neBot.nonempty_of_mem h).ne_empty rfl)

/-- Łoś 定理的官方形态：超积上语句为真 ⟺ 结构层几乎处处为真。 -/
example {α : Type*} (u : Ultrafilter α) (M : α → Type*)
    [∀ a, Nonempty (M a)]
    {L : Language} [∀ a, L.Structure (M a)] (φ : L.Sentence) :
    (u : Filter α).Product M ⊨ φ ↔ ∀ᶠ a : α in u, M a ⊨ φ :=
  FirstOrder.Language.Ultraproduct.sentence_realize (M := M) (u := u) φ

end Settheory.Ch83
