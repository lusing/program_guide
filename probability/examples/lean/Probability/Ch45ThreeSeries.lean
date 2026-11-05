import Mathlib.Probability.BorelCantelli
import Mathlib.Probability.Martingale.OptionalStopping

/-!
# 第 45 章 级数收敛与三级数定理（Lean）

胡书 §6.1-6.2 的机器侧。主件是三件精确账：

- **调和发散的二进块证书**：每个块 `∑_{2^m ≤ k < 2^{m+1}} 1/k ≥ 1/2`，
  于是 `H_{2^M} ≥ M/2`——`Σvar` 发散（α = 1/2 情形）的可验证据；
- **`Σ 1/k² ≤ 1` 的望远镜证书**：`1/k² ≤ 1/(k-1) - 1/k` 后裂项相消——
  `Σvar` 收敛（α = 1 情形）的可验上界；
- **三级数的截断账**：具体有理数组在 `d = 1` 下的 (a)(b)(c) 三条部分和
  逐项判定。

锚点：`MeasureTheory.maximal_ineq`（Doob 极大不等式——Kolmogorov
不等式 6.1.1 的鞅原形）与 `ProbabilityTheory.measure_limsup_eq_one`
（第二 Borel–Cantelli，三级数定理 (a) 发散侧的引擎）。
-/

open MeasureTheory

#check @MeasureTheory.maximal_ineq
-- Doob 极大不等式：非负下鞅的 sup' 尾概率 × ε ≤ 尾段积分。
-- 取 f = (Sₖ − ESₖ)² 即得 Kolmogorov 不等式 6.1.1 的鞅面

#check @ProbabilityTheory.measure_limsup_eq_one
-- 第二 Borel–Cantelli：独立事件列和发散 ⟹ 无限次发生。
-- (a) 发散 ⟹ |Xₙ| ≥ d 无穷多次 ⟹ 原级数 a.s. 不收敛

/-! ## 望远镜求和引理 -/

/-- 裂项相消的一般形式：`∑_{i<m} (f i − f (i+1)) = f 0 − f m`。 -/
private theorem sum_telescope (f : ℕ → ℚ) (m : ℕ) :
    ∑ i ∈ Finset.range m, (f i - f (i + 1)) = f 0 - f m := by
  induction m with
  | zero => norm_num
  | succ m ih =>
      rw [Finset.sum_range_succ, ih]
      ring

/-! ## 调和级数的二进块下界 -/

/-- 每个二进块内每项 `≥ 1/2^{m+1}`，块内恰 `2^m` 项，故块和 `≥ 1/2`。 -/
theorem dyadic_block_ge (m : ℕ) :
    ∑ k ∈ Finset.Ico (2 ^ m : ℕ) (2 ^ (m + 1) : ℕ), (1 : ℚ) / ((k : ℕ)) ≥ 1 / 2 := by
  have hp2 : (2 : ℕ) ^ (m + 1) = 2 ^ m + 2 ^ m := by
    rw [pow_succ]
    omega
  have hcard : (Finset.Ico (2 ^ m : ℕ) (2 ^ (m + 1) : ℕ)).card = 2 ^ m := by
    rw [Nat.card_Ico, hp2]
    have := Nat.two_pow_pos m
    omega
  have hposk : (0 : ℚ) < ((2 ^ (m + 1) : ℕ) : ℚ) := by
    exact_mod_cast Nat.two_pow_pos _
  have hle : ∀ k ∈ Finset.Ico (2 ^ m : ℕ) (2 ^ (m + 1) : ℕ),
      (1 : ℚ) / ((2 ^ (m + 1) : ℕ) : ℚ) ≤ (1 : ℚ) / ((k : ℕ) : ℚ) := by
    intro k hk
    have h2 : k < 2 ^ (m + 1) := (Finset.mem_Ico.mp hk).2
    have hkq2 : ((k : ℕ) : ℚ) < ((2 ^ (m + 1) : ℕ) : ℚ) := by exact_mod_cast h2
    have hpos : (0 : ℚ) < ((k : ℕ) : ℚ) := by
      exact_mod_cast le_trans (Nat.one_le_two_pow (n := m)) (Finset.mem_Ico.mp hk).1
    field_simp
    linarith
  have hstart : (1 / 2 : ℚ)
      = ((2 ^ m : ℕ) : ℚ) * ((1 : ℚ) / ((2 ^ (m + 1) : ℕ) : ℚ)) := by
    have ha : (0 : ℚ) < ((2 ^ m : ℕ) : ℚ) := by exact_mod_cast Nat.two_pow_pos m
    rw [hp2]
    push_cast
    field_simp
    norm_num
  have hconst : ∑ _k ∈ Finset.Ico (2 ^ m : ℕ) (2 ^ (m + 1) : ℕ),
      (1 : ℚ) / ((2 ^ (m + 1) : ℕ) : ℚ)
      = ((2 ^ m : ℕ) : ℚ) * ((1 : ℚ) / ((2 ^ (m + 1) : ℕ) : ℚ)) := by
    rw [Finset.sum_const, hcard, nsmul_eq_mul]
  calc (1 / 2 : ℚ) = ((2 ^ m : ℕ) : ℚ) * ((1 : ℚ) / ((2 ^ (m + 1) : ℕ) : ℚ)) :=
        hstart
    _ = ∑ _k ∈ Finset.Ico (2 ^ m : ℕ) (2 ^ (m + 1) : ℕ),
          (1 : ℚ) / ((2 ^ (m + 1) : ℕ) : ℚ) := hconst.symm
    _ ≤ ∑ k ∈ Finset.Ico (2 ^ m : ℕ) (2 ^ (m + 1) : ℕ),
          (1 : ℚ) / ((k : ℕ) : ℚ) := Finset.sum_le_sum hle

/-- `H_{2^M} = ∑_{k<2^M} 1/k ≥ M/2`：调和级数发散的二进块账。
方差版：`Xₖ = ±k^{-1/2}` 的 `var(Xₖ) = 1/k`，`Σvar = ∞`——三级数 (c) 发散。 -/
theorem harmonic_dyadic_lb (M : ℕ) :
    ∑ k ∈ Finset.range (2 ^ M : ℕ), (1 : ℚ) / ((k : ℕ)) ≥ (M : ℚ) / 2 := by
  induction M with
  | zero => norm_num
  | succ M ih =>
      have hsplit : Finset.range (2 ^ (M + 1) : ℕ)
          = Finset.range (2 ^ M : ℕ) ∪ Finset.Ico (2 ^ M : ℕ) (2 ^ (M + 1) : ℕ) := by
        ext k
        simp only [Finset.mem_union, Finset.mem_range, Finset.mem_Ico]
        omega
      have hdisj : Disjoint (Finset.range (2 ^ M : ℕ))
          (Finset.Ico (2 ^ M : ℕ) (2 ^ (M + 1) : ℕ)) :=
        by
          rw [Finset.disjoint_right]
          intro a ha2 hmem
          have := (Finset.mem_Ico.mp ha2).1
          have := Finset.mem_range.mp hmem
          omega
      rw [hsplit, Finset.sum_union hdisj]
      have hblock := dyadic_block_ge M
      have hfinal : (M : ℚ) / 2 + 1 / 2 = ((M + 1 : ℕ) : ℚ) / 2 := by
        push_cast
        ring
      have hsum := add_le_add ih hblock
      linarith [hsum, hfinal]

/-! ## `Σ 1/k² ≤ 1` 的望远镜证书 -/

/-- 裂项相消（range 形式）：`∑_{i<m} (1/(i+1) − 1/(i+2)) = 1 − 1/(m+1)`，
即 `∑_{k=2}^{m+1} (1/(k−1) − 1/k) = 1 − 1/(m+1)`。 -/
theorem telescoping_range (m : ℕ) :
    ∑ i ∈ Finset.range m, ((1 : ℚ) / (((i : ℕ) + 1)) - (1 : ℚ) / (((i : ℕ) + 2)))
      = 1 - (1 : ℚ) / (((m : ℕ) + 1)) := by
  induction m with
  | zero => norm_num
  | succ m ih =>
      rw [Finset.sum_range_succ, ih]
      push_cast
      ring

/-- 逐项控制：`1/k² ≤ 1/(k-1) - 1/k`（k ≥ 2，右侧裂项恰为 `1/(k(k-1))`）。 -/
theorem term_bound (k : ℕ) (hk : 2 ≤ k) :
    (1 : ℚ) / (((k : ℕ) : ℚ) * ((k : ℕ) : ℚ))
      ≤ (1 : ℚ) / (((k : ℕ) : ℚ) - 1) - (1 : ℚ) / (((k : ℕ) : ℚ)) := by
  have hpos2 : (0 : ℚ) < ((k : ℕ) : ℚ) := by exact_mod_cast (show 0 < k by omega)
  have hpos1 : (0 : ℚ) < (((k : ℕ) : ℚ) - 1) := by
    have hk2 : (2 : ℚ) ≤ ((k : ℕ) : ℚ) := by exact_mod_cast hk
    linarith
  have hrw : (1 : ℚ) / (((k : ℕ) : ℚ) - 1) - (1 : ℚ) / (((k : ℕ) : ℚ))
      = (1 : ℚ) / ((((k : ℕ) : ℚ) - 1) * ((k : ℕ) : ℚ)) := by
    field_simp
    linarith
  have hprod : (0 : ℚ) < (((k : ℕ) : ℚ) - 1) * ((k : ℕ) : ℚ) := by positivity
  have key : (((k : ℕ) : ℚ) - 1) * ((k : ℕ) : ℚ)
      ≤ ((k : ℕ) : ℚ) * ((k : ℕ) : ℚ) := by
    have hexp : (((k : ℕ) : ℚ) - 1) * ((k : ℕ) : ℚ)
        = ((k : ℕ) : ℚ) * ((k : ℕ) : ℚ) - ((k : ℕ) : ℚ) := by ring
    rw [hexp]
    linarith
  rw [hrw, one_div_le_one_div (by positivity) hprod]
  exact key

/-- 方差收敛证书：`∑_{i<m} 1/(i+2)² ≤ 1`。
方差版：`Xₖ = ±1/k` 的 `var(Xₖ) = 1/k²`，`Σvar ≤ 2`——三级数 (c) 收敛。 -/
theorem sq_sum_bound (m : ℕ) :
    ∑ i ∈ Finset.range m, (1 : ℚ) / ((((i : ℕ) + 2)) * (((i : ℕ) + 2))) ≤ 1 := by
  have hle : ∀ i ∈ Finset.range m,
      (1 : ℚ) / ((((i : ℕ) + 2)) * (((i : ℕ) + 2)))
        ≤ (1 : ℚ) / (((((i : ℕ) + 2) : ℕ) - 1)) - (1 : ℚ) / (((i : ℕ) + 2)) := by
    intro i _
    have h := term_bound (i + 2) (by omega)
    push_cast at h ⊢
    exact h
  have hsplit := Finset.sum_le_sum hle
  have heq : ∑ i ∈ Finset.range m,
      ((1 : ℚ) / (((((i : ℕ) + 2) : ℕ) - 1)) - (1 : ℚ) / (((i : ℕ) + 2)))
        = ∑ i ∈ Finset.range m, ((1 : ℚ) / (((i : ℕ) + 1)) - (1 : ℚ) / (((i : ℕ) + 2))) := by
    refine Finset.sum_congr rfl fun i _ => ?_
    push_cast
    have e : (((i : ℕ) : ℚ) + 2 - 1) = (((i : ℕ) : ℚ) + 1) := by linarith
    rw [e]
  rw [heq] at hsplit
  have htel := telescoping_range m
  rw [htel] at hsplit
  have h1 : (1 : ℚ) - 1 / (((m : ℕ) + 1)) ≤ 1 := by
    have : (0 : ℚ) < (((m : ℕ) + 1)) := by positivity
    have := div_nonneg (le_refl (1 : ℚ)) this.le
    linarith
  linarith

/-! ## 三级数的截断账（具体数组） -/

/-- 三级数 (a)：越过阈值 `d` 的项数（有限数组上的精确计数）。 -/
def seriesA (vs : List ℚ) (d : ℚ) : ℕ :=
  (vs.filter fun v => |v| ≥ d).length

/-- 三级数 (b)：截断后的中心账（确定性数组的截尾和）。 -/
def seriesB (vs : List ℚ) (d : ℚ) : ℚ :=
  (vs.filter fun v => |v| < d).sum

/-- 三级数 (c)：截断后的方差账（截尾平方和）。 -/
def seriesC (vs : List ℚ) (d : ℚ) : ℚ :=
  ((vs.filter fun v => |v| < d).map fun v => v * v).sum

/-- 收敛候选 `±1/k` 的前 6 项在 `d = 1` 下的三账：
(a) 恰 1 项越线（首项 ±1），(b) 截尾和从 1/2 起步，(c) 平方和有界起步。 -/
example : seriesA [1, -1 / 2, 1 / 3, -1 / 4, 1 / 5, -1 / 6] 1 = 1 := by
  norm_num [seriesA]

example : seriesB [1, -1 / 2, 1 / 3, -1 / 4, 1 / 5, -1 / 6] 1
    = -1 / 2 + 1 / 3 - 1 / 4 + 1 / 5 - 1 / 6 := by
  norm_num [seriesB]

example : seriesC [1, -1 / 2, 1 / 3, -1 / 4, 1 / 5, -1 / 6] 1
    = 1 / 4 + 1 / 9 + 1 / 16 + 1 / 25 + 1 / 36 := by
  norm_num [seriesC]

/-- 发散候选 `k^{-1/2}` 的方差账前 6 项（α = 1/2 情形，d = 2 全截）：
(c) 的部分和 = 调和级数开头——注定发散（见 `dyadic_block_ge`）。 -/
example : seriesC [1, 1 / 2, 1 / 3, 1 / 4, 1 / 5, 1 / 6] 2
    = 1 + 1 / 4 + 1 / 9 + 1 / 16 + 1 / 25 + 1 / 36 := by
  norm_num [seriesC]
