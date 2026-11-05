import Mathlib.Topology.MetricSpace.Basic
import Mathlib.Topology.MetricSpace.Bounded
import Mathlib.Topology.Order.DenselyOrdered
import Mathlib.Algebra.Order.Archimedean.Basic
import Mathlib.Tactic

/-!
# 第 09 章 拓扑定义

对应原书第 9 章：度量三公理、有界、邻域（开球）、极限点、闭集、
稠密、内点、开集、邻域是开集、完备集。舞台主要是 ℝ 上的通常距离。
-/

namespace Realanalysis.Ch09

open Metric Set Bornology

/-! ## 9.1 度量 -/

/-- 实直线的距离就是绝对值。 -/
example (p q : ℝ) : dist p q = |p - q| := Real.dist_eq p q

example (p : ℝ) : dist p p = 0 := dist_self p

example (p q : ℝ) : dist p q = dist q p := dist_comm p q

/-- 三角不等式。 -/
example (p q r : ℝ) : dist p q ≤ dist p r + dist r q := dist_triangle p r q

/-- 子集配上同一个距离仍是度量空间：类型 `Set.Icc` 自动继承。 -/
example (p q : Set.Icc (-3 : ℝ) 3) : dist p q = dist q p := dist_comm p q

/-! ## 9.2 有界 -/

/-- 例 9.4：[-3,3] 以 0 和 M=3 为界。 -/
example : ∀ p ∈ Icc (-3 : ℝ) 3, dist p 0 ≤ 3 := by
  intro p hp
  rw [Real.dist_eq, abs_le]
  constructor <;> linarith [hp.1, hp.2]

example : IsBounded (Icc (-3 : ℝ) 3) := isBounded_Icc (-3) 3

/-- 两个有界集的并有界（定理 9.5 的二元情形）。 -/
example {s t : Set ℝ} (hs : IsBounded s) (ht : IsBounded t) : IsBounded (s ∪ t) :=
  hs.union ht

/-- 定理 9.6 的一个方向：度量有界推出既有上界又有下界。 -/
example {E : Set ℝ} {q M : ℝ} (h : ∀ p ∈ E, dist p q ≤ M) :
    (∀ p ∈ E, q - M ≤ p) ∧ (∀ p ∈ E, p ≤ q + M) := by
  constructor <;> intro p hp <;>
    have := h p hp <;> rw [Real.dist_eq, abs_le] at this <;> linarith

/-! ## 9.3 邻域 -/

/-- 例 9.8：半径 3、中心 0 的邻域就是 (-3,3)。 -/
example : ball (0 : ℝ) 3 = Ioo (-3) 3 := by
  simpa using Real.ball_eq_Ioo (0 : ℝ) 3

/-- 闭区间的端点不在开球里：|3-0|=3 不小于半径 3。 -/
example : (3 : ℝ) ∉ ball 0 3 := by
  simp [mem_ball]

/-- 定理 9.23：每个邻域都是开集。 -/
example (p : ℝ) (r : ℝ) : IsOpen (ball p r) := isOpen_ball

/-! ## 9.4 开集、闭集、极限点 -/

example : IsOpen (Ioo (-3 : ℝ) 3) := isOpen_Ioo

example : IsClosed (Icc (-3 : ℝ) 3) := isClosed_Icc

/-- 空集既开又闭（例 9.26 第一条）。 -/
example : IsOpen (∅ : Set ℝ) := isOpen_empty
example : IsClosed (∅ : Set ℝ) := isClosed_empty

/-- 内点：[-3,3] 的内部是 (-3,3)，端点不是内点。 -/
example : interior (Icc (-3 : ℝ) 3) = Ioo (-3) 3 := interior_Icc

example : (3 : ℝ) ∉ interior (Icc (-3) 3) := by
  simp [interior_Icc]

/-- 例 9.10 / 9.14：3 是 (-3,3) 的极限点，却不在集合里，所以开区间不闭。 -/
example : (3 : ℝ) ∈ closure (Ioo (-3) 3) := by
  rw [closure_Ioo (by norm_num : (-3 : ℝ) ≠ 3)]
  simp

example : ¬ IsClosed (Ioo (-3 : ℝ) 3) := by
  intro h
  have h3 : (3 : ℝ) ∈ closure (Ioo (-3) 3) := by
    rw [closure_Ioo (by norm_num : (-3 : ℝ) ≠ 3)]
    simp
  rw [h.closure_eq] at h3
  simp at h3

/-- 推论 9.15：有限集是闭集。 -/
example : IsClosed ({0, 1} : Set ℝ) := by
  have hf : ({0, 1} : Set ℝ).Finite := by simp
  exact hf.isClosed

/-! ## 9.5 稠密与完备 -/

/-- 定理 9.18：ℚ 在 ℝ 中稠密。每个区间 (x-ε, x+ε) 里都有有理数
    （定理 5.6 / `exists_rat_btwn`）。 -/
example : Dense (Set.range ((↑) : ℚ → ℝ)) := by
  rw [dense_iff]
  intro x r hr
  obtain ⟨q, h1, h2⟩ := exists_rat_btwn (show x - r < x + r by linarith)
  refine ⟨(q : ℝ), ?_⟩
  refine ⟨?_, ⟨q, rfl⟩⟩
  rw [mem_ball, Real.dist_eq, abs_lt]
  constructor <;> linarith

/-- 闭集在全空间稠密当且仅当它就是全空间。 -/
example {E : Set ℝ} (hE : IsClosed E) : Dense E ↔ E = univ := by
  constructor
  · intro h
    rw [← hE.closure_eq]
    exact h.closure_eq
  · rintro rfl
    exact dense_univ

/-- [-3,3] 的闭包等于自身，且每个点都在闭包里：它是完备集的原型。 -/
example : closure (Icc (-3 : ℝ) 3) = Icc (-3) 3 := isClosed_Icc.closure_eq

end Realanalysis.Ch09
