import Mathlib.Topology.MetricSpace.Basic
import Mathlib.Topology.Order.DenselyOrdered
import Mathlib.Topology.Order.Monotone
import Mathlib.Topology.Constructions
import Mathlib.Algebra.Order.Archimedean.Basic
import Mathlib.Tactic

/-!
# 第 10 章 闭集和开集

对应原书第 10 章：开集的补是闭集，任意并与任意交，有限交与有限并，
闭包是最小闭超集，上确界落在闭包里，以及相对某个子空间的开集和闭集。
-/

namespace Realanalysis.Ch10

open Metric Set

/-! ## 10.1 补集 -/

/-- 定理 10.1：E 开当且仅当补集闭。 -/
example {E : Set ℝ} : IsOpen E ↔ IsClosed Eᶜ := isClosed_compl_iff.symm

/-- 推论 10.2：F 闭当且仅当补集开。 -/
example {F : Set ℝ} : IsClosed F ↔ IsOpen Fᶜ := isOpen_compl_iff.symm

/-! ## 10.2 任意并、任意交 -/

/-- 定理 10.3：任意多个开集的并仍开。 -/
example {ι : Type*} {G : ι → Set ℝ} (h : ∀ i, IsOpen (G i)) : IsOpen (⋃ i, G i) :=
  isOpen_iUnion h

/-- 定理 10.3 的另一半：任意多个闭集的交仍闭。 -/
example {ι : Type*} {F : ι → Set ℝ} (h : ∀ i, IsClosed (F i)) : IsClosed (⋂ i, F i) :=
  isClosed_iInter h

/-! ## 10.3 有限交、有限并，以及无限时的反例 -/

/-- 定理 10.4：两个开集的交仍开。有限个的情形是把半径取最小。 -/
example {G₁ G₂ : Set ℝ} (h₁ : IsOpen G₁) (h₂ : IsOpen G₂) : IsOpen (G₁ ∩ G₂) :=
  h₁.inter h₂

/-- 有限指标上的交：`Finite ι` 提供“取最小半径”那一步。 -/
example {ι : Type*} [Finite ι] {G : ι → Set ℝ} (h : ∀ i, IsOpen (G i)) :
    IsOpen (⋂ i, G i) :=
  isOpen_iInter_of_finite h

/-- 定理 10.4 的另一半：两个闭集的并仍闭。 -/
example {F₁ F₂ : Set ℝ} (h₁ : IsClosed F₁) (h₂ : IsClosed F₂) : IsClosed (F₁ ∪ F₂) :=
  h₁.union h₂

/-- 例：∩ (-1/(n+1), 1/(n+1)) = {0}。每一项都开，无限交是单点。 -/
theorem nestedIooInter :
    ⋂ n : ℕ, Ioo (-(1 / ((n : ℝ) + 1))) (1 / ((n : ℝ) + 1)) = {(0 : ℝ)} := by
  ext x
  simp only [mem_iInter, mem_Ioo, mem_singleton_iff]
  constructor
  · intro hx
    by_contra h
    have habs : 0 < |x| := abs_pos.mpr h
    obtain ⟨n, hn⟩ := exists_nat_one_div_lt habs
    have hlt : |x| < 1 / ((n : ℝ) + 1) := abs_lt.mpr (hx n)
    linarith
  · rintro rfl n
    have : 0 < 1 / ((n : ℝ) + 1) := by positivity
    constructor <;> linarith

/-- 单点在 ℝ 里不是开集：半径 ε 的邻域里还有 ε/2。 -/
theorem notOpenSingletonZero : ¬ IsOpen ({(0 : ℝ)} : Set ℝ) := by
  intro h
  obtain ⟨ε, hε, hsub⟩ := (Metric.isOpen_iff.mp h) 0 (by simp)
  have hhalf : ε / 2 ∈ ball (0 : ℝ) ε := by
    simp only [mem_ball, Real.dist_eq, sub_zero]
    have hpos : 0 < ε / 2 := by linarith
    rw [abs_of_pos hpos]
    linarith
  have : ε / 2 ∈ ({0} : Set ℝ) := hsub hhalf
  simp at this
  linarith

/-- 无限个开集的交可以不开。 -/
example : ¬ IsOpen (⋂ n : ℕ, Ioo (-(1 / ((n : ℝ) + 1))) (1 / ((n : ℝ) + 1))) := by
  rw [nestedIooInter]
  exact notOpenSingletonZero

/-- 例：∪ [0, 2 - 1/(n+1)] = [0, 2)。每一项都闭，无限并不闭。 -/
theorem nestedIccUnion :
    ⋃ n : ℕ, Icc (0 : ℝ) (2 - 1 / ((n : ℝ) + 1)) = Ico 0 2 := by
  ext x
  simp only [mem_iUnion, mem_Icc, mem_Ico]
  constructor
  · rintro ⟨n, hx0, hx2⟩
    have : 0 < 1 / ((n : ℝ) + 1) := by positivity
    exact ⟨hx0, by linarith⟩
  · rintro ⟨hx0, hx2⟩
    obtain ⟨n, hn⟩ := exists_nat_one_div_lt (show 0 < 2 - x by linarith)
    exact ⟨n, hx0, by linarith⟩

example : ¬ IsClosed (⋃ n : ℕ, Icc (0 : ℝ) (2 - 1 / ((n : ℝ) + 1))) := by
  rw [nestedIccUnion]
  intro h
  have h2 : (2 : ℝ) ∈ closure (Ico 0 2) := by
    rw [closure_Ico (by norm_num : (0 : ℝ) ≠ 2)]
    simp
  rw [h.closure_eq] at h2
  simp at h2

/-! ## 10.4 闭包 -/

/-- 例 10.6：(-3, 3) 的闭包是 [-3, 3]。 -/
example : closure (Ioo (-3 : ℝ) 3) = Icc (-3) 3 :=
  closure_Ioo (by norm_num : (-3 : ℝ) ≠ 3)

/-- 定理 10.7：闭包总是闭集。 -/
example {E : Set ℝ} : IsClosed (closure E) := isClosed_closure

/-- 推论 10.8：等于自己的闭包，当且仅当它是闭集。 -/
example {E : Set ℝ} : closure E = E ↔ IsClosed E := closure_eq_iff_isClosed

/-- 推论 10.9：闭包是包含 E 的最小闭集。 -/
example {E F : Set ℝ} (hEF : E ⊆ F) (hF : IsClosed F) : closure E ⊆ F :=
  closure_minimal hEF hF

/-! ## 10.5 上确界落在闭包里 -/

/-- 定理 10.10：有上界的非空集，上确界在闭包里。 -/
example {E : Set ℝ} (hne : E.Nonempty) (hb : BddAbove E) : sSup E ∈ closure E :=
  csSup_mem_closure hne hb

/-- 下确界同样落在闭包里。 -/
example {E : Set ℝ} (hne : E.Nonempty) (hb : BddBelow E) : sInf E ∈ closure E :=
  csInf_mem_closure hne hb

/-- 推论 10.11：闭集还把它的上确界收进自己。 -/
example {E : Set ℝ} (hc : IsClosed E) (hne : E.Nonempty) (hb : BddAbove E) :
    sSup E ∈ E :=
  hc.csSup_mem hne hb

/-- 逆命题不成立：[-3, 0) ∪ (0, 3] 含有端点 -3 和 3，但 0 是极限点。 -/
example : (-3 : ℝ) ∈ Ico (-3) 0 ∪ Ioc 0 3 := by simp

example : (3 : ℝ) ∈ Ico (-3) 0 ∪ Ioc 0 3 := by simp

example : (0 : ℝ) ∉ Ico (-3) 0 ∪ Ioc 0 3 := by simp

example : ¬ IsClosed (Ico (-3 : ℝ) 0 ∪ Ioc 0 3) := by
  intro h
  have hsub : Ioo (0 : ℝ) 3 ⊆ Ico (-3) 0 ∪ Ioc 0 3 := by
    intro x hx
    exact Or.inr ⟨hx.1, hx.2.le⟩
  have h0 : (0 : ℝ) ∈ closure (Ioo 0 3) := by
    rw [closure_Ioo (by norm_num : (0 : ℝ) ≠ 3)]
    simp
  have : (0 : ℝ) ∈ closure (Ico (-3) 0 ∪ Ioc 0 3) := closure_mono hsub h0
  rw [h.closure_eq] at this
  simp at this

/-! ## 10.6 相对开集、相对闭集 -/

/-- 定理 10.14：子空间里的开集，就是全空间某个开集交上子空间。 -/
example {Y : Set ℝ} {E : Set Y} :
    IsOpen E ↔ ∃ G : Set ℝ, IsOpen G ∧ Subtype.val ⁻¹' G = E :=
  isOpen_induced_iff

/-- [0, 1) 在 [0, 2) 里开：它是 (-1, 1) 在子空间上的原像。 -/
example : IsOpen (Subtype.val ⁻¹' (Ioo (-1 : ℝ) 1) : Set (Ico (0 : ℝ) 2)) :=
  isOpen_Ioo.preimage continuous_subtype_val

/-- 同一个 [0, 1) 在 ℝ 里不开：0 的每个邻域都跑到负数。 -/
example : ¬ IsOpen (Ico (0 : ℝ) 1) := by
  intro h
  have hinter : interior (Ico (0 : ℝ) 1) = Ico 0 1 := h.interior_eq
  rw [interior_Ico] at hinter
  have : (0 : ℝ) ∈ Ioo 0 1 := by
    rw [hinter]
    simp [mem_Ico]
  simp [mem_Ioo] at this

/-- 例 10.16：[1, 2) 在 [0, 2) 里闭，它是 [1, ∞) 在子空间上的原像。 -/
example : IsClosed (Subtype.val ⁻¹' (Ici (1 : ℝ)) : Set (Ico (0 : ℝ) 2)) :=
  isClosed_Ici.preimage continuous_subtype_val

/-- 同一个 [1, 2) 在 ℝ 里不闭：2 在闭包里，却不在集合里。 -/
example : ¬ IsClosed (Ico (1 : ℝ) 2) := by
  intro h
  have h2 : (2 : ℝ) ∈ closure (Ico 1 2) := by
    rw [closure_Ico (by norm_num : (1 : ℝ) ≠ 2)]
    simp
  rw [h.closure_eq] at h2
  simp [mem_Ico] at h2

end Realanalysis.Ch10
