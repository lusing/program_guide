import Mathlib.Data.Set.Basic
import Mathlib.Order.Interval.Set.Basic
import Mathlib.Algebra.Order.Archimedean.Basic
import Mathlib.Tactic

/-!
# 第 02 章 集合论：并、交、补与德摩根律

对应原书第 3 章《集合论》：集合与子集、区间、并交补运算、
定理 3.12 的分配性质、定理 3.17 德摩根律，以及索引族的
无限并/无限交（例 3.14 的三组区间例子）。
-/

open Set

namespace Realanalysis.Ch02

variable {α : Type*} (A B C : Set α)

/-- 定理 3.7：空集是任何集合的子集。证明是“空集没有元素”的
    自动推论——vacuous truth。 -/
example : (∅ : Set α) ⊆ A := empty_subset A

/-- 定理 3.12 性质 1：A ⊆ A ∪ B 且 A ∩ B ⊆ A。
    4.35 中集合级包含直接用成员级推理写出。 -/
example : A ⊆ A ∪ B := fun _ hx => Or.inl hx
example : A ∩ B ⊆ A := fun _ hx => hx.1

/-- 定理 3.12 性质 2/3：A ⊆ B 当且仅当并集被 B 吸收、
    交集被 A 吸收。 -/
example : A ⊆ B ↔ A ∪ B = B := (union_eq_right).symm
example : A ⊆ B ↔ A ∩ B = A := (inter_eq_left).symm

/-- 定理 3.12 性质 4/5：并对交、交对并的分配律。 -/
example : A ∪ (B ∩ C) = (A ∪ B) ∩ (A ∪ C) := union_inter_distrib_left A B C
example : A ∩ (B ∪ C) = (A ∩ B) ∪ (A ∩ C) := inter_union_distrib_left A B C

/-- 定理 3.17 德摩根律（两集合版）：补集把并与交互换。 -/
example : (A ∪ B)ᶜ = Aᶜ ∩ Bᶜ := compl_union A B
example : (A ∩ B)ᶜ = Aᶜ ∪ Bᶜ := compl_inter A B

/-- 德摩根律的索引族版本：无限并的补 = 补的无限交，反之亦然。 -/
example (I : Type*) (E : I → Set α) : (⋃ i, E i)ᶜ = ⋂ i, (E i)ᶜ :=
  compl_iUnion (s := E)
example (I : Type*) (E : I → Set α) : (⋂ i, E i)ᶜ = ⋃ i, (E i)ᶜ :=
  compl_iInter (s := E)

section Intervals

/-- 原书例 3.9 的区间记号：开区间 Ioo、闭区间 Icc、半开 Ico/Ioc。 -/
example : Set.Ioo (-3 : ℝ) 3 = {x | -3 < x ∧ x < 3} := by ext x; simp [mem_Ioo]
example : Set.Icc (0 : ℝ) 99.5 = {x | 0 ≤ x ∧ x ≤ 99.5} := by ext x; simp [mem_Icc]

/-- 原书提醒：(1,3) ∪ (3,5) ≠ (1,5)，因为点 3 被漏掉了。 -/
example : Set.Ioo (1 : ℝ) 3 ∪ Set.Ioo 3 5 ≠ Set.Ioo 1 5 := by
  intro h
  have h3 : (3 : ℝ) ∈ Set.Ioo (1 : ℝ) 5 := ⟨by norm_num, by norm_num⟩
  rw [←h] at h3
  simp only [mem_union, mem_Ioo] at h3
  rcases h3 with ⟨-, h⟩ | ⟨h, -⟩ <;> linarith

/-- 而 (1,3) ∩ (3,5) = ∅：两个开区间在端点处不相交。 -/
example : Set.Ioo (1 : ℝ) 3 ∩ Set.Ioo 3 5 = (∅ : Set ℝ) := by
  ext x
  refine ⟨fun h => ?_, fun h => h.elim⟩
  simp only [mem_inter_iff, mem_Ioo] at h
  linarith

end Intervals

section IndexedFamily

/-- 例 3.14 之一：A_n = (-1/(n+1), 1/(n+1))（Lean 的 ℕ 从 0 开始，
    故用 n+1 对齐原书 n ≥ 1）。嵌套递减集合的并 = 最大的 A_0。 -/
def Aseq (n : ℕ) : Set ℝ := Set.Ioo (-(1 : ℝ) / (n + 1)) (1 / (n + 1))

theorem union_Aseq : ⋃ n : ℕ, Aseq n = Set.Ioo (-1 : ℝ) 1 := by
  apply Set.Subset.antisymm
  · -- 每个 A_n 都在 Ioo (-1) 1 里
    apply iUnion_subset
    intro n x hx
    simp only [Aseq, mem_Ioo] at hx
    rcases hx with ⟨hxlo, hxhi⟩
    have hpos : (0 : ℝ) < (n : ℝ) + 1 := by linarith
    have hle : (1 : ℝ) / ((n : ℝ) + 1) ≤ 1 :=
      (div_le_one hpos).mpr (by linarith)
    -- -1/(n+1) 解析为 (-1)/(n+1)，与 1/(n+1) 是不同的除法原子，
    -- 用 neg_div 显式建立下界 -1 ≤ -1/(n+1)，linarith 才能贯通。
    have hlo_bound : (-1 : ℝ) ≤ (-1 : ℝ) / ((n : ℝ) + 1) := by
      rw [neg_div]; exact neg_le_neg hle
    exact ⟨by linarith, by linarith⟩
  · -- Ioo (-1) 1 = A_0，直接落进并集
    intro x hx
    exact mem_iUnion.mpr ⟨0, by simpa [Aseq] using hx⟩

/-- 例 3.14 之二：B_n = [0, 2 - 1/(n+1)]。递增集合族：
    并集是半开区间 [0, 2)——点 2 永远不被任何有限 n 捕获。 -/
def Bseq (n : ℕ) : Set ℝ := Set.Icc (0 : ℝ) (2 - 1 / (n + 1))

theorem union_Bseq : ⋃ n : ℕ, Bseq n = Set.Ico (0 : ℝ) 2 := by
  apply Set.Subset.antisymm
  · intro x hx
    rcases mem_iUnion.mp hx with ⟨n, hn⟩
    simp only [Bseq, mem_Icc] at hn
    rw [mem_Ico]
    constructor
    · exact hn.1
    · have hpos : (0 : ℝ) < 1 / (n + 1) := by positivity
      linarith
  · intro x hx
    rw [mem_Ico] at hx
    -- Archimedean 性质：找 n 使 1/(n+1) < 2-x，则 x ≤ 2-1/(n+1)
    have hε : 0 < 2 - x := by linarith
    obtain ⟨n, hn⟩ := exists_nat_one_div_lt hε
    refine mem_iUnion.mpr ⟨n, ?_⟩
    simp only [Bseq, mem_Icc]
    constructor
    · exact hx.1
    · linarith

/-- 例 3.14 之三：同一递增族的交集 = 最小的 B_0 = [0,1]。 -/
theorem inter_Bseq : ⋂ n : ℕ, Bseq n = Set.Icc (0 : ℝ) 1 := by
  apply Set.Subset.antisymm
  · -- 交集中的元素必在 B_0 中，而 B_0 = Icc 0 1
    intro x hx
    have h0 := mem_iInter.mp hx 0
    simp only [Bseq, mem_Icc] at h0
    exact ⟨h0.1, by linarith⟩
  · intro x hx
    have hx' : 0 ≤ x ∧ x ≤ 1 := by simpa [mem_Icc] using hx
    rw [mem_iInter]
    intro (n : ℕ)
    simp only [Bseq, mem_Icc]
    have hpos : (0 : ℝ) < (n : ℝ) + 1 := by linarith
    have hle : (1 : ℝ) / ((n : ℝ) + 1) ≤ 1 :=
      (div_le_one hpos).mpr (by linarith)
    constructor
    · exact hx'.1
    · linarith

end IndexedFamily

end Realanalysis.Ch02
