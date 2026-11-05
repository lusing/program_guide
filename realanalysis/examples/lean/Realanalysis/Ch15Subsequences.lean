import Mathlib.Analysis.SpecificLimits.Basic
import Mathlib.Topology.Algebra.Monoid.Defs
import Mathlib.Topology.Algebra.GroupWithZero
import Mathlib.Topology.Sequences
import Mathlib.Topology.MetricSpace.Sequences
import Mathlib.Topology.Order.Compact
import Mathlib.Order.Filter.AtTopBot.Tendsto
import Mathlib.Tactic

/-!
# 第 15 章 极限与子序列

对应原书第 15 章：极限的和、数乘、积、倒数，分量收敛，
子序列，紧集与有界序列中的收敛子序列。
柯西序列和发散到无穷属于后面的章。
-/

namespace Realanalysis.Ch15

open Filter Set Bornology Metric

/-! ## 15.1 极限的代数运算 -/

/-- 定理 15.1（1）：和的极限是极限的和。两边各让出 ε/2。 -/
theorem add_limits {s t : ℕ → ℝ} {a b : ℝ}
    (hs : Tendsto s atTop (nhds a)) (ht : Tendsto t atTop (nhds b)) :
    Tendsto (fun n => s n + t n) atTop (nhds (a + b)) :=
  hs.add ht

/-- 定理 15.1（2）：常数可以加到序列上，也可以乘到序列上。 -/
theorem const_add_limit {s : ℕ → ℝ} {a c : ℝ} (hs : Tendsto s atTop (nhds a)) :
    Tendsto (fun n => c + s n) atTop (nhds (c + a)) :=
  tendsto_const_nhds.add hs

theorem const_mul_limit {s : ℕ → ℝ} {a c : ℝ} (hs : Tendsto s atTop (nhds a)) :
    Tendsto (fun n => c * s n) atTop (nhds (c * a)) :=
  Filter.Tendsto.const_mul c hs

/-- 定理 15.1（3）：积的极限是极限的积。 -/
theorem mul_limits {s t : ℕ → ℝ} {a b : ℝ}
    (hs : Tendsto s atTop (nhds a)) (ht : Tendsto t atTop (nhds b)) :
    Tendsto (fun n => s n * t n) atTop (nhds (a * b)) :=
  hs.mul ht

/-- 定理 15.1（4）：极限非零时，倒数的极限是极限的倒数。
    尾部自动躲开 0，因为项最终落进半径 |a|/2 的球里。 -/
theorem inv_limit {s : ℕ → ℝ} {a : ℝ} (hs : Tendsto s atTop (nhds a)) (ha : a ≠ 0) :
    Tendsto (fun n => (s n)⁻¹) atTop (nhds a⁻¹) :=
  hs.inv₀ ha

/-- 1/(n+1) + 1 → 1。误差整个来自调和项。 -/
theorem harmonic_plus_one :
    Tendsto (fun n : ℕ => 1 / ((n : ℝ) + 1) + 1) atTop (nhds 1) := by
  have h :=
    tendsto_one_div_add_atTop_nhds_zero_nat.add (tendsto_const_nhds : Tendsto (fun _ : ℕ => (1 : ℝ)) atTop (nhds 1))
  simpa using h

/-- 3/(n+1) → 0。 -/
theorem three_harmonic :
    Tendsto (fun n : ℕ => (3 : ℝ) * (1 / ((n : ℝ) + 1))) atTop (nhds 0) := by
  simpa using Filter.Tendsto.const_mul (3 : ℝ) tendsto_one_div_add_atTop_nhds_zero_nat

/-! ## 15.2–15.3 向量与内积 -/

/-- 定理 15.2：平面上的序列收敛，当且仅当两个分量各自收敛。 -/
theorem pair_tendsto_iff {u v : ℕ → ℝ} {a b : ℝ} :
    Tendsto (fun n => (u n, v n)) atTop (nhds (a, b)) ↔
      Tendsto u atTop (nhds a) ∧ Tendsto v atTop (nhds b) := by
  constructor
  · intro h
    exact ⟨(continuous_fst.tendsto (a, b)).comp h, (continuous_snd.tendsto (a, b)).comp h⟩
  · rintro ⟨hu, hv⟩
    exact hu.prodMk_nhds hv

/-- (1/(n+1), 3) → (0, 3)。第二个分量是常数。 -/
theorem harmonic_pair :
    Tendsto (fun n : ℕ => (1 / ((n : ℝ) + 1), (3 : ℝ))) atTop (nhds ((0 : ℝ), 3)) :=
  tendsto_one_div_add_atTop_nhds_zero_nat.prodMk_nhds tendsto_const_nhds

/-- 定理 15.3（3）的二维情形：内积的极限是极限的内积。 -/
theorem dot_limit {u v : ℕ → ℝ × ℝ} {a b : ℝ × ℝ}
    (hu : Tendsto u atTop (nhds a)) (hv : Tendsto v atTop (nhds b)) :
    Tendsto (fun n => (u n).1 * (v n).1 + (u n).2 * (v n).2) atTop
      (nhds (a.1 * b.1 + a.2 * b.2)) := by
  have hu1 := (continuous_fst.tendsto (x := a)).comp hu
  have hu2 := (continuous_snd.tendsto (x := a)).comp hu
  have hv1 := (continuous_fst.tendsto (x := b)).comp hv
  have hv2 := (continuous_snd.tendsto (x := b)).comp hv
  exact (hu1.mul hv1).add (hu2.mul hv2)

/-! ## 15.4–15.6 子序列 -/

/-- 偶数下标严格递增。 -/
theorem even_strictMono : StrictMono (fun k : ℕ => 2 * k) := by
  intro a b hab
  simpa [two_mul] using Nat.add_lt_add hab hab

theorem odd_strictMono : StrictMono (fun k : ℕ => 2 * k + 1) := by
  intro a b hab
  exact Nat.add_lt_add_right (even_strictMono hab) 1

theorem even_alt : Tendsto (fun k : ℕ => (-1 : ℝ) ^ (2 * k)) atTop (nhds 1) := by
  have heq : (fun k : ℕ => (-1 : ℝ) ^ (2 * k)) = fun _ => (1 : ℝ) := by
    ext k
    rw [pow_mul]
    norm_num
  rw [heq]
  exact tendsto_const_nhds

theorem odd_alt : Tendsto (fun k : ℕ => (-1 : ℝ) ^ (2 * k + 1)) atTop (nhds (-1)) := by
  have heq : (fun k : ℕ => (-1 : ℝ) ^ (2 * k + 1)) = fun _ => (-1 : ℝ) := by
    ext k
    rw [pow_add, pow_one, pow_mul]
    norm_num
  rw [heq]
  exact tendsto_const_nhds

/-- 定理 15.6 的一个方向：收敛序列的每个子序列都收敛到同一个极限。 -/
theorem subseq_of_tendsto {s : ℕ → ℝ} {p : ℝ} {φ : ℕ → ℕ}
    (hs : Tendsto s atTop (nhds p)) (hφ : StrictMono φ) :
    Tendsto (s ∘ φ) atTop (nhds p) :=
  hs.comp hφ.tendsto_atTop

/-- 另一个方向：序列本身就是沿恒等下标取出的子序列。 -/
theorem tendsto_of_all_subseq {s : ℕ → ℝ} {p : ℝ}
    (h : ∀ φ : ℕ → ℕ, StrictMono φ → Tendsto (s ∘ φ) atTop (nhds p)) :
    Tendsto s atTop (nhds p) := by
  simpa using h id strictMono_id

/-- (-1)^n 有两条子序列分别走向 1 和 -1，所以整条序列不收敛。 -/
theorem alt_not_convergent :
    ¬ ∃ p : ℝ, Tendsto (fun n : ℕ => (-1 : ℝ) ^ n) atTop (nhds p) := by
  intro h
  obtain ⟨p, hp⟩ := h
  have h1 : Tendsto (fun k => (-1 : ℝ) ^ (2 * k)) atTop (nhds p) :=
    hp.comp even_strictMono.tendsto_atTop
  have hm1 : Tendsto (fun k => (-1 : ℝ) ^ (2 * k + 1)) atTop (nhds p) :=
    hp.comp odd_strictMono.tendsto_atTop
  have hp1 : p = 1 := tendsto_nhds_unique h1 even_alt
  have hpm : p = -1 := tendsto_nhds_unique hm1 odd_alt
  have : (1 : ℝ) = -1 := hp1.symm.trans hpm
  norm_num at this

/-- 这两条子序列极限组成的集合是闭的。定理 15.9 的一般论证见教程正文。 -/
theorem two_limits_closed : IsClosed ({(-1 : ℝ)} ∪ {1}) :=
  isClosed_singleton.union isClosed_singleton

/-! ## 15.7–15.8 紧集与波尔查诺–魏尔斯特拉斯 -/

/-- 定理 15.7：落在紧区间里的序列有收敛子序列，极限仍在区间里。 -/
theorem unit_interval_subseq {s : ℕ → ℝ} (hs : ∀ n, s n ∈ Icc (0 : ℝ) 1) :
    ∃ a ∈ Icc (0 : ℝ) 1, ∃ φ : ℕ → ℕ, StrictMono φ ∧ Tendsto (s ∘ φ) atTop (nhds a) :=
  isCompact_Icc.tendsto_subseq hs

/-- 定理 15.8：有界序列有收敛子序列。极限落在值域的闭包里，可以在值域外面。 -/
theorem bolzano_weierstrass {s : ℕ → ℝ} {E : Set ℝ}
    (hE : IsBounded E) (hs : ∀ n, s n ∈ E) :
    ∃ a ∈ closure E, ∃ φ : ℕ → ℕ, StrictMono φ ∧ Tendsto (s ∘ φ) atTop (nhds a) :=
  tendsto_subseq_of_bounded hE hs

end Realanalysis.Ch15
