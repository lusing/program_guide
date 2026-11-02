import Mathlib.Tactic

/-!
# 第 25 章：收敛模式反例的有限计数代数

不进入测度论，只验证反例背后的**有理数代数恒等式**：

* 移动区间（typewriter）每层 `2^k` 个区间、每个长度 `1/2^k`：层内总长度恒为 1，
  所以 `Σ P(Z_n = 1)` 随层数线性发散（不满足第一 Borel–Cantelli 的条件），
  而单项概率 `2^{-k} → 0`（依概率收敛）；
* 尖峰序列 `P(Z_n ≠ 0) = 1/n²`：部分和有界 `≤ 2 - 1/N`（满足 Borel–Cantelli 条件）；
* 独立 Bernoulli(1/n)：`∏ (1 - 1/(i+2)) = 1/(N+1)`，调和级数发散对应“无事件概率 → 0”。
-/

namespace Ch25

/-- 第 k 层有 `2^k` 个区间、每个长 `1/2^k`，层内总长度为 1。 -/
theorem level_total (k : ℕ) : ∑ _i ∈ Finset.range (2 ^ k), (1 : ℚ) / 2 ^ k = 1 := by
  simp

/-- 前 `K+1` 层的概率总和 `Σ P(Z_n = 1) = K + 1`：线性发散。 -/
theorem levels_sum (K : ℕ) :
    ∑ k ∈ Finset.range (K + 1), ∑ _i ∈ Finset.range (2 ^ k), (1 : ℚ) / 2 ^ k = K + 1 := by
  induction K with
  | zero => simp
  | succ K ih =>
    rw [Finset.sum_range_succ, ih, level_total]
    push_cast
    ring

/-- 单项概率 `1/2^k` 随层数严格下降到 0（依概率收敛的原因）：`1/2^(k+1) < 1/2^k`。 -/
theorem level_prob_decreasing (k : ℕ) : (1 : ℚ) / 2 ^ (k + 1) < 1 / 2 ^ k := by
  have h : (0 : ℚ) < 2 ^ k := by positivity
  rw [pow_succ]
  rw [div_lt_div_iff₀ (by positivity) h]
  nlinarith

/-- 尖峰序列：`Σ_{i<N+1} 1/(i+1)² ≤ 2 - 1/(N+1)`，部分和有界（Borel–Cantelli 条件成立）。 -/
theorem spike_sum_bounded (N : ℕ) :
    ∑ i ∈ Finset.range (N + 1), (1 : ℚ) / ((i : ℚ) + 1) ^ 2 ≤ 2 - 1 / ((N : ℚ) + 1) := by
  induction N with
  | zero => norm_num
  | succ N ih =>
    rw [Finset.sum_range_succ]
    have hN : (0 : ℚ) < (N : ℚ) + 1 := by positivity
    have key : 1 / (((N + 1 : ℕ) : ℚ) + 1) ^ 2 ≤ 1 / ((N : ℚ) + 1) - 1 / (((N + 1 : ℕ) : ℚ) + 1) := by
      push_cast
      rw [div_sub_div _ _ (by positivity) (by positivity), div_le_div_iff₀ (by positivity) (by positivity)]
      nlinarith [sq_nonneg (N : ℚ), hN]
    push_cast at key ih ⊢
    linarith

/-- 独立 Bernoulli(1/n)，从 n=2 起：`P(前 N 项全无事件) = ∏ (1 - 1/(i+2)) = 1/(N+1) → 0`。 -/
theorem no_event_prod (N : ℕ) :
    ∏ i ∈ Finset.range N, (1 - 1 / ((i : ℚ) + 2)) = 1 / ((N : ℚ) + 1) := by
  induction N with
  | zero => simp
  | succ N ih =>
    rw [Finset.prod_range_succ, ih]
    push_cast
    have h1 : (N : ℚ) + 1 ≠ 0 := by positivity
    have h2 : (N : ℚ) + 2 ≠ 0 := by positivity
    field_simp
    ring

/-- 具体数值：移动区间第 3 层（k=3）有 8 个区间，每个长 1/8；总和 1；单项概率 1/8。 -/
theorem level3 : ∑ _i ∈ Finset.range 8, (1 : ℚ) / 8 = 1 := by norm_num

/-- 依分布的不连续点：`N(0,1/n)` 在 0 处恒为 1/2，而极限分布（点质量）在 0 处为 1。 -/
theorem cdf_at_discontinuity : (1 : ℚ) / 2 ≠ 1 := by norm_num

end Ch25
