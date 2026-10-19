import Mathlib.MeasureTheory.Measure.Restrict

/-!
# 第 06 章 测度的逼近（Lean）

严书 §1.6。核心是测度论里最重要的元定理：**两个 σ-有限测度若在
一个 π-系上相等（且该 π-系生成 σ-代数并覆盖全空间），则两测度相等**。
mathlib 的对应物：`ext_of_generateFrom_of_iUnion`（Measure/Restrict.lean:495）。

下面的例子把唯一性机器开到 ℕ 上：以 C = {Iic n} 为 π-系，
先证 σ(C) 就是全空间（单点集可由 Iic (k+1) 与 Iic k 之差拼出），
再由"在初始段上相等"推出两测度全等。
-/

open MeasureTheory
open scoped ENNReal

/-- C = {Iic n : n ∈ ℕ} 生成 ℕ 上的（离散）σ-代数：
单点集 {0} = Iic 0，{k+1} = Iic (k+1) ∩ (Iic k)ᶜ，
任意子集是可数个单点集之并。 -/
private theorem iic_gen :
    (MeasurableSpace.generateFrom {s : Set ℕ | ∃ n, s = Set.Iic n}) = ⊤ := by
  set C : Set (Set ℕ) := {s | ∃ n, s = Set.Iic n} with hC
  refine le_antisymm le_top ?_
  have hsg : ∀ k : ℕ, MeasurableSet[MeasurableSpace.generateFrom C] {k} := by
    intro k
    rcases k with _ | k'
    · have hE : ({0} : Set ℕ) = Set.Iic 0 := by
        ext x
        simp only [Set.mem_singleton_iff, Set.mem_Iic]
        omega
      exact MeasurableSpace.measurableSet_generateFrom ⟨0, hE⟩
    · have hE : ({k' + 1} : Set ℕ) = Set.Iic (k' + 1) ∩ (Set.Iic k')ᶜ := by
        ext x
        simp only [Set.mem_singleton_iff, Set.mem_inter_iff, Set.mem_Iic, Set.mem_compl_iff]
        omega
      have h1 : MeasurableSet[MeasurableSpace.generateFrom C] (Set.Iic (k' + 1)) :=
        MeasurableSpace.measurableSet_generateFrom ⟨k' + 1, rfl⟩
      have h2 : MeasurableSet[MeasurableSpace.generateFrom C] (Set.Iic k') :=
        MeasurableSpace.measurableSet_generateFrom ⟨k', rfl⟩
      rw [hE]
      exact h1.inter h2.compl
  intro t _
  have hEq : t = ⋃ k ∈ t, ({k} : Set ℕ) := by
    ext x
    simp
  rw [hEq]
  exact MeasurableSet.biUnion (Set.to_countable t) (fun k _ => hsg k)

/-- 唯一性定理（严书 1.6 的机器版）：若 μ 有限且两测度在初始段族
{Iic n} 上相等，则 μ = ν。 -/
example (μ ν : Measure ℕ) (hfin : μ Set.univ ≠ ∞)
    (h : ∀ n : ℕ, μ (Set.Iic n) = ν (Set.Iic n)) : μ = ν := by
  set C : Set (Set ℕ) := {s | ∃ n, s = Set.Iic n} with hC
  -- π-系：Iic a ∩ Iic b = Iic (a ⊓ b)
  have hpi : IsPiSystem C := by
    intro s hs t ht _
    obtain ⟨a, rfl⟩ := hs
    obtain ⟨b, rfl⟩ := ht
    exact ⟨a ⊓ b, Set.Iic_inter_Iic⟩
  -- 覆盖列与有限性
  have h1B : (⋃ i, Set.Iic (i : ℕ)) = Set.univ := by
    ext x
    simp only [Set.mem_iUnion, Set.mem_univ, iff_true]
    exact ⟨x, le_refl x⟩
  have hμB : ∀ i : ℕ, μ (Set.Iic i) ≠ ∞ := by
    intro i hcon
    have hle : μ (Set.Iic i) ≤ μ Set.univ := measure_mono (Set.subset_univ (Set.Iic i))
    rw [hcon] at hle
    exact hfin (le_antisymm le_top hle)
  -- 生成性：由前例，σ(C) = ⊤；再把环境实例与 ⊤ 等同
  have hgen : (MeasurableSpace.generateFrom C) = ⊤ := by
    rw [hC]
    exact iic_gen
  have hA : ((inferInstance : MeasurableSpace ℕ)) = MeasurableSpace.generateFrom C := by
    have htop : (⊤ : MeasurableSpace ℕ) = (inferInstance : MeasurableSpace ℕ) :=
      MeasurableSpace.ext fun s =>
        ⟨fun _ => Set.Countable.measurableSet (Set.to_countable s), fun _ => trivial⟩
    rw [hgen]
    exact htop.symm
  exact Measure.ext_of_generateFrom_of_iUnion C (fun i => Set.Iic i) hA hpi h1B
    (fun i => ⟨i, rfl⟩) hμB (by rintro s ⟨n, rfl⟩; exact h n)
