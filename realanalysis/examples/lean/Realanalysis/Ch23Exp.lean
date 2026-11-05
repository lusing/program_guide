import Mathlib.Analysis.Complex.Exponential
import Mathlib.Analysis.Normed.Algebra.Exponential
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.SpecialFunctions.Exponential
import Mathlib.NumberTheory.Real.Irrational
import Mathlib.Tactic

/-!
# 第 23 章 数 e 与指数函数（补充章）

原书第 19 章只点了 e 的名字。这一章用级数定义 e，证明 e 的无理性。
-/

namespace Realanalysis.Ch23

open Filter
open scoped Topology
open scoped Nat

/-- 指数级数 ∑ x^n/n! 对任意实数 x 收敛。 -/
theorem exp_series_summable (x : ℝ) : Summable (fun n : ℕ => x ^ n / n !) :=
  NormedSpace.expSeries_div_summable x

/-- 指数级数的和就是 exp x。 -/
theorem exp_series_hasSum (x : ℝ) : HasSum (fun n : ℕ => x ^ n / n !) (Real.exp x) := by
  rw [Real.exp_eq_exp_ℝ]
  exact NormedSpace.expSeries_div_hasSum_exp x

/-- e = exp 1 = ∑ 1/n!。 -/
theorem exp_one_series : HasSum (fun n : ℕ => (1 : ℝ) / n !) (Real.exp 1) := by
  simpa using exp_series_hasSum 1

/-- e 的前几项：1 + 1 + 1/2 = 5/2。 -/
theorem exp_one_partial : (1 : ℝ) + 1 + 1 / 2 = 5 / 2 := by norm_num

/-- e 的前四项部分和：1 + 1 + 1/2 + 1/6 = 8/3。 -/
theorem exp_one_partial_four : (1 : ℝ) + 1 + 1 / 2 + 1 / 6 = 8 / 3 := by norm_num

/-- e 的前五项部分和：1 + 1 + 1/2 + 1/6 + 1/24 = 65/24。 -/
theorem exp_one_partial_five : (1 : ℝ) + 1 + 1 / 2 + 1 / 6 + 1 / 24 = 65 / 24 := by norm_num

/-- e > 1：指数函数在正数处大于 1。 -/
theorem exp_one_gt_one : (1 : ℝ) < Real.exp 1 :=
  Real.one_lt_exp_iff.mpr zero_lt_one

/-- e ≤ 3：用 exp_bound' 在 x = 1, n = 1 处估计。 -/
theorem exp_one_le_three : Real.exp 1 ≤ 3 := by
  have h := Real.exp_bound' (by norm_num : (0 : ℝ) ≤ 1) (by norm_num : (1 : ℝ) ≤ 1)
    (n := 1) (by norm_num)
  simp [Nat.factorial] at h
  norm_num at h ⊢
  linarith

/-- 指数函数的函数方程：exp(x+y) = exp x * exp y。 -/
theorem exp_add (x y : ℝ) : Real.exp (x + y) = Real.exp x * Real.exp y :=
  Real.exp_add x y

/-- exp(-x) = 1/exp x。 -/
theorem exp_neg (x : ℝ) : Real.exp (-x) = (Real.exp x)⁻¹ :=
  Real.exp_neg x

/-- 辅助：正项可和级数的和严格大于任何部分和（若后面还有正项）。 -/
theorem tsum_lt_of_pos_tail {f : ℕ → ℝ} (hf : Summable f) (hpos : ∀ n, 0 ≤ f n)
    (N : ℕ) (hN : 0 < f N) :
    (∑ n ∈ Finset.range N, f n) < ∑' n, f n := by
  have hsplit := hf.sum_add_tsum_nat_add N
  have htail : 0 < ∑' n, f (n + N) := by
    apply Summable.tsum_pos _ (fun n => hpos _) 0 (by simpa using hN)
    exact (hf.comp_injective (add_left_injective N))
  rw [← hsplit]
  linarith

/-- e 是无理数（Fourier 证明）。
设 e = p/q，q ≥ 1。令 S = ∑_{m=0}^{q} 1/m!，则 q!·S 是整数。
q!·e = p·(q-1)! 也是整数，所以 q!·(e - S) 是整数。
但 exp_bound' 给出 0 < e - S < 1/(q·q!)，所以 0 < q!·(e - S) < 1/q ≤ 1。
整数严格介于 0 和 1 之间，矛盾。 -/
theorem irrational_e : Irrational (Real.exp 1) := by
  rw [irrational_iff_ne_rational]
  intro p q hq h
  -- 把 q 归约为正整数：若 q < 0，用 -p/(-q) 替换
  wlog hq_pos_int : 0 < q with H
  · exact H (-p) (-q) (neg_ne_zero.mpr hq)
      (by push_cast; rw [neg_div_neg_eq]; exact h) (by omega)
  have hq1 : (1 : ℤ) ≤ q := by omega
  have hq_pos : (0 : ℝ) < (q : ℝ) := by exact_mod_cast hq_pos_int
  -- 用 N = q.toNat，N ≥ 1
  obtain ⟨N, hN⟩ : ∃ N : ℕ, (N : ℤ) = q := ⟨q.toNat, Int.toNat_of_nonneg (by omega)⟩
  have hN1 : 1 ≤ N := by omega
  have hqN : (N : ℝ) = q := by exact_mod_cast hN
  -- 令 S = ∑_{m=0}^{N} 1/m!
  set S := ∑ m ∈ Finset.range (N + 1), (1 : ℝ) / m.factorial with hS_def
  -- q! · S 是整数：每一项 N!/m! 都是整数
  have hS_int : ∃ k : ℤ, (N.factorial : ℝ) * S = k := by
    have hterm : ∀ m : ℕ, m ≤ N → ∃ k : ℤ, (N.factorial : ℝ) * (1 / m.factorial) = k := by
      intro m hmq
      obtain ⟨c, hc⟩ := Nat.factorial_dvd_factorial hmq
      refine ⟨c, ?_⟩
      have hm_pos : (0 : ℝ) < (m.factorial : ℝ) := by
        exact_mod_cast Nat.factorial_pos m
      rw [hc]; push_cast
      field_simp
    -- 定义 g m = N!/m! 的整数见证（m ≤ N 时），否则 0
    choose f hf using hterm
    let g : ℕ → ℤ := fun m => if h : m ≤ N then f m h else 0
    refine ⟨∑ m ∈ Finset.range (N + 1), g m, ?_⟩
    rw [Finset.mul_sum]; push_cast
    exact Finset.sum_congr rfl (fun m hm => by
      have hmq : m ≤ N := Nat.le_of_lt_succ (Finset.mem_range.mp hm)
      show (N.factorial : ℝ) * (1 / m.factorial) = ↑(g m)
      simp only [g, show m ≤ N from hmq, dite_eq_left]
      exact hf m hmq)
  -- N! · e = p · (N-1)! 是整数
  have he_int : ∃ k : ℤ, (N.factorial : ℝ) * Real.exp 1 = k := by
    refine ⟨p * (N - 1).factorial, ?_⟩
    rw [h]
    have hN_succ : N = (N - 1) + 1 := by omega
    calc (N.factorial : ℝ) * ((p : ℝ) / (q : ℝ))
        = (N.factorial : ℝ) * p / (N : ℝ) := by rw [hqN]; ring
      _ = p * ((N - 1).factorial : ℝ) := by
        conv_lhs => rw [hN_succ, Nat.factorial_succ]
        push_cast
        have hN_cast : ((N - 1 + 1 : ℕ) : ℝ) = (N : ℝ) := by congr 1; omega
        have hN_ne : (N : ℝ) ≠ 0 := by
          have : N ≠ 0 := by omega
          exact_mod_cast this
        field_simp
      _ = ↑(p * (N - 1).factorial) := by push_cast; ring
  -- 差 N!·(e - S) 是整数
  obtain ⟨k₁, hk₁⟩ := he_int
  obtain ⟨k₂, hk₂⟩ := hS_int
  have hdiff_int : ∃ k : ℤ, (N.factorial : ℝ) * (Real.exp 1 - S) = k :=
    ⟨k₁ - k₂, by push_cast; rw [mul_sub, hk₁, hk₂]⟩
  -- exp_bound' 给出上界
  have hbound := Real.exp_bound' (by norm_num : (0 : ℝ) ≤ 1) (by norm_num : (1 : ℝ) ≤ 1)
    (n := N + 1) (by omega)
  simp only [one_pow, one_mul] at hbound
  -- hbound : exp 1 ≤ (∑ m ∈ range (N+1), 1/m!) + (N+2)/((N+1)!·(N+1))
  have he_sub : Real.exp 1 - S ≤ ((N : ℝ) + 2) /
      ((N + 1).factorial * (N + 1)) := by
    have hS_eq : S = ∑ m ∈ Finset.range (N + 1), (1 : ℝ) / m.factorial := rfl
    rw [hS_eq]
    push_cast at hbound ⊢
    have : ((N : ℝ) + 1 + 1) = (N : ℝ) + 2 := by ring
    rw [this] at hbound
    linarith
  -- e > S：正项级数的和大于部分和
  have he_gt : S < Real.exp 1 := by
    have htsum := (exp_one_series).tsum_eq
    rw [← htsum]
    exact tsum_lt_of_pos_tail (exp_series_summable 1 |>.congr (fun n => by simp))
      (fun n => by positivity) (N + 1) (by positivity)
  -- 综合：0 < N!·(e - S) < 1，但它是整数
  obtain ⟨k, hk⟩ := hdiff_int
  have hN_fact_pos : (0 : ℝ) < (N.factorial : ℝ) := by exact_mod_cast Nat.factorial_pos _
  have hk_pos : (0 : ℝ) < k := by rw [← hk]; exact mul_pos hN_fact_pos (by linarith)
  have hk_lt_one : (k : ℝ) < 1 := by
    rw [← hk]
    calc (N.factorial : ℝ) * (Real.exp 1 - S)
        ≤ (N.factorial : ℝ) * (((N : ℝ) + 2) /
          ((N + 1).factorial * (N + 1))) :=
          mul_le_mul_of_nonneg_left he_sub (le_of_lt hN_fact_pos)
      _ < 1 := by
        have hN1r : (1 : ℝ) ≤ (N : ℝ) := by exact_mod_cast hN1
        have hfact_succ : (N + 1).factorial = (N + 1) * N.factorial := Nat.factorial_succ _
        rw [hfact_succ]; push_cast
        -- N! * ((N+2) / ((N+1) * N! * (N+1))) = (N+2) / ((N+1)^2)
        rw [mul_div_assoc', div_lt_one (by positivity)]
        -- 目标：(N+1) * N! * (N+1) > N! * (N+2)
        -- 即 (N+1)^2 * N! > N! * (N+2)，约去 N!（正），即 (N+1)^2 > N+2
        have hN_ne : (N.factorial : ℝ) ≠ 0 := ne_of_gt hN_fact_pos
        have h1 : (N : ℝ) + 2 < ((N : ℝ) + 1) ^ 2 := by nlinarith
        nlinarith [hN_fact_pos]
  -- k 是整数，0 < k < 1，矛盾
  have : (0 : ℤ) < k := by exact_mod_cast hk_pos
  have : k < 1 := by exact_mod_cast hk_lt_one
  omega

end Realanalysis.Ch23
