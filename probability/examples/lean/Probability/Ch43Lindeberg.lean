import Mathlib.Algebra.Field.GeomSum
import Mathlib.Probability.CentralLimitTheorem

/-!
# 第 43 章 Lindeberg 条件（Lean）

胡书 §5.3 的机器侧。mathlib 没有 Lindeberg 定理——同分布情形以
`ProbabilityTheory.tendstoInDistribution_inv_sqrt_mul_sum` 为锚
（注 5.3.3：iid + 有限方差时 Lindeberg 条件自动成立）。主件自建：

- 两点分布数组 ±σₖ 的 **Lindeberg 商**（判据 `σₖ² ≥ ε²·cₙ²` 两边平方，
  全程有理数）；
- **例 5.3.1 的几何方差账**：`∑_{k<n} 2^k = 2^n − 1`、末项份额恒 `1/2`；
- 两个一般 n 定理：多项式方差族（σₖ² = k）的商在 `n ≥ 6` 后精确为 0
  （民主：权力分散），几何方差族的商恒为 `3/4`
  （独裁：末项永不退位）。
-/

open MeasureTheory

#check @ProbabilityTheory.tendstoInDistribution_inv_sqrt_mul_sum
-- iid、零均值、单位方差的标准化和依分布收敛到 N(0,1)：
-- Lindeberg 条件的同分布特例（胡书注 5.3.3——iid 时条件自动成立）

#check @ProbabilityTheory.tendstoInDistribution_inv_sqrt_mul_sum_sub
-- 中心化版本：非零均值时先减 n·E[X]

/-! ## 两个主控引理：2 的幂单调 -/

private theorem two_pow_pos (n : ℕ) : (0 : ℚ) < 2 ^ n := pow_pos (by norm_num) n

private theorem two_pow_le {a b : ℕ} (h : a ≤ b) : (2 : ℚ) ^ a ≤ (2 : ℚ) ^ b := by
  induction h with
  | refl => norm_num
  | @step c _hc ih =>
      have h0 : (0 : ℚ) < 2 ^ c := two_pow_pos c
      have h2 : (0 : ℚ) < 2 := by norm_num
      rw [Nat.succ_eq_add_one]
      calc (2 : ℚ) ^ a ≤ 2 ^ c := ih
        _ ≤ 2 ^ c * 2 := by nlinarith
        _ = 2 ^ (c + 1) := (pow_succ 2 c).symm

private theorem two_pow_lt {a b : ℕ} (h : a < b) : (2 : ℚ) ^ a < (2 : ℚ) ^ b := by
  obtain ⟨d, hd⟩ := Nat.exists_eq_add_of_le (Nat.le_of_lt h)
  have hd1 : 1 ≤ d := by omega
  obtain ⟨e, he⟩ := Nat.exists_eq_add_of_le hd1
  have hle : (2 : ℚ) ^ a ≤ 2 ^ (a + e) := two_pow_le (by omega)
  have hpe : (0 : ℚ) < 2 ^ (a + e) := two_pow_pos _
  have hstep : (2 : ℚ) ^ ((a + e) + 1) = 2 ^ (a + e) * 2 := pow_succ _ _
  have hb : b = (a + e) + 1 := by omega
  have h2 : (0 : ℚ) < 2 := by norm_num
  rw [hb, hstep]
  nlinarith

/-! ## 两点数组的 Lindeberg 商 -/

/-- 两点分布 ±σₖ（等概率、σₖ² = `sig2` 的第 k 项）数组的 Lindeberg 商：
超过阈值 `ε·cₙ` 的项（判据两边平方 `σₖ² ≥ ε²·cₙ²`）的方差占比。
被积函数 `∫_{|x|≥εcₙ} x² dFₖ` 对两点分布恰为 `σₖ²·1{σₖ² ≥ ε²cₙ²}`。 -/
def twoPointLindebergQuot (sig2 : List ℚ) (eps : ℚ) : ℚ :=
  let c2 := sig2.sum
  (sig2.map fun s => if s ≥ eps * eps * c2 then s else 0).sum / c2

/-- 多项式族 σₖ² = 1..7、ε = 1/2：cₙ² = 28，阈值 7 恰被末项踩线，
商 = 7/28 = 1/4（最后一个越线者尚未退场）。 -/
example : twoPointLindebergQuot [1, 2, 3, 4, 5, 6, 7] (1 / 2) = 1 / 4 := by
  norm_num [twoPointLindebergQuot]

/-- 同族 n = 8：cₙ² = 36，阈值 9 已越过全体（最大 8），商精确归零——
"民主条件成立"的整数证书。 -/
example : twoPointLindebergQuot [1, 2, 3, 4, 5, 6, 7, 8] (1 / 2) = 0 := by
  norm_num [twoPointLindebergQuot]

/-- 有界族（σₖ² = 3，胡书注 5.3.2 的场景）：n = 4 时阈值 3 恰被踩线
（越线判据是闭的：`|x| ≥ εcₙ`），商 = 1。 -/
example : twoPointLindebergQuot [3, 3, 3, 3] (1 / 2) = 1 := by
  norm_num [twoPointLindebergQuot]

/-- 有界族 n = 5：cₙ² = 15，阈值 15/4 > 3 越过全体，商归零——
有界方差 + `cₙ → ∞` 时 Lindeberg 条件自动成立。 -/
example : twoPointLindebergQuot [3, 3, 3, 3, 3] (1 / 2) = 0 := by
  norm_num [twoPointLindebergQuot]

/-! ## 例 5.3.1：几何方差族的独裁账 -/

/-- 例 5.3.1 的核心恒等式：`∑_{k<n} 2^k = 2^n − 1`。
方差序列 1, 1, 2, 4, …, 2^{n−2} 的总方差 `cₙ² = 2^{n−1}` 由此而来。 -/
example (n : ℕ) : ∑ k ∈ Finset.range n, (2 : ℚ) ^ k = 2 ^ n - 1 := by
  rw [geom_sum_eq (by norm_num : (2 : ℚ) ≠ 1)]
  norm_num

/-- 末项份额恒为 1/2：无论加多少项，最后一项永远占总方差的一半——
Feller 条件（`max σₖ²/cₙ² → 0`）永不成立。 -/
example (n : ℕ) (hn : 2 ≤ n) : (2 : ℚ) ^ (n - 2) / 2 ^ (n - 1) = 1 / 2 := by
  have e : n - 1 = (n - 2) + 1 := by omega
  have h : (2 : ℚ) ^ (n - 1) = 2 ^ (n - 2) * 2 := by rw [e, pow_succ]
  rw [h]
  field_simp

/-! ## 一般 n 的两条定理：民主归零，独裁不退位 -/

/-- 多项式族 σₖ² = k、阈值判据 `8k < n(n+1)`（即 `k < n(n+1)/8 =
ε²·cₙ²`，ε = 1/2）下的越线项。 -/
def polyTerm (n k : ℕ) : ℚ :=
  if (8 : ℚ) * k < (n : ℚ) * ((n : ℚ) + 1) then 0 else (k : ℚ)

/-- **民主归零**：方差 σₖ² = k 的多项式族，ε = 1/2 的 Lindeberg 商
在 `n ≥ 6` 后精确为 0——阈值越过所有 `k ≤ n−1`，没有越线者。
关键代数：`n(n+1) − 8(n−1) = (n−1)(n−6) + 2 > 0`。 -/
theorem polyQuot_zero (n : ℕ) (hn : 6 ≤ n) :
    ∑ k ∈ Finset.range n, polyTerm n k = 0 := by
  refine Finset.sum_eq_zero fun k hk => ?_
  have hk' : k < n := Finset.mem_range.mp hk
  have hn1 : (1 : ℕ) ≤ n := le_trans (by norm_num) hn
  have hcast : ((n - 1 : ℕ) : ℚ) = (n : ℚ) - 1 := Nat.cast_sub hn1
  have h11 : (0 : ℚ) ≤ (n : ℚ) - 1 := by
    have h : (0 : ℕ) ≤ n - 1 := by omega
    rw [← hcast]
    exact_mod_cast h
  have h16 : (0 : ℚ) ≤ (n : ℚ) - 6 := by
    have h0 : (0 : ℚ) ≤ ((n - 6 : ℕ) : ℚ) := by
      have h : (0 : ℕ) ≤ n - 6 := by omega
      exact_mod_cast h
    rw [Nat.cast_sub hn] at h0
    simpa using h0
  have key : (n : ℚ) * ((n : ℚ) + 1) - 8 * ((n : ℚ) - 1)
      = ((n : ℚ) - 1) * ((n : ℚ) - 6) + 2 := by
    ring
  have hkn : (k : ℚ) ≤ ((n - 1 : ℕ) : ℚ) := by
    have h : k ≤ n - 1 := by omega
    exact_mod_cast h
  rw [hcast] at hkn
  have h1 : (8 : ℚ) * k ≤ 8 * ((n : ℚ) - 1) :=
    mul_le_mul_of_nonneg_left hkn (by norm_num : (0 : ℚ) ≤ 8)
  have h2 : 8 * ((n : ℚ) - 1) < (n : ℚ) * ((n : ℚ) + 1) := by
    have hnn : (0 : ℚ) ≤ ((n : ℚ) - 1) * ((n : ℚ) - 6) := mul_nonneg h11 h16
    linarith [key, hnn]
  show polyTerm n k = 0
  simp only [polyTerm, if_pos (by linarith : (8 : ℚ) * k < (n : ℚ) * ((n : ℚ) + 1))]

/-- 例 5.3.1 方差序列的第 k 项：1, 1, 2, 4, …, 2^{k−1}。 -/
def geoValue (k : ℕ) : ℚ := if k = 0 then 1 else (2 : ℚ) ^ (k - 1)

/-- 几何族在阈值 `2^m`（= ε²·cₙ²，ε = 1/2、cₙ² = 2^{m+2}）下的越线项。 -/
def geoTerm (m k : ℕ) : ℚ := if geoValue k ≥ (2 : ℚ) ^ m then geoValue k else 0

/-- **独裁不退位**：几何族 n = m+3 项、ε = 1/2 的 Lindeberg 商恒等于
`3/4`——越线方差（末两项 `2^m + 2^{m+1}`）占总方差 `2^{m+2}` 的比例
纹丝不动。 -/
theorem geoQuot_const (m : ℕ) (hm : 1 ≤ m) :
    (∑ k ∈ Finset.range (m + 3), geoTerm m k) / (2 : ℚ) ^ (m + 2) = 3 / 4 := by
  -- 三步拆尾：∑_{k<m+3} = ∑_{k<m} + f m + f (m+1) + f (m+2)
  have split : ∑ k ∈ Finset.range (m + 3), geoTerm m k
      = ∑ k ∈ Finset.range m, geoTerm m k + geoTerm m m + geoTerm m (m + 1)
        + geoTerm m (m + 2) := by
    rw [show m + 3 = (m + 2) + 1 from by omega, Finset.sum_range_succ,
      show m + 2 = (m + 1) + 1 from by omega, Finset.sum_range_succ,
      Finset.sum_range_succ]
  rw [split]
  -- 前段全零：k = 0 时 1 < 2^m（m ≥ 1）；1 ≤ k < m 时 2^{k-1} < 2^m
  have head : ∑ k ∈ Finset.range m, geoTerm m k = 0 := by
    refine Finset.sum_eq_zero fun k hk => ?_
    have hkm : k < m := Finset.mem_range.mp hk
    rcases Nat.eq_zero_or_pos k with hk0 | hk0
    · have h2m : (1 : ℚ) < (2 : ℚ) ^ m := by
        have hle := two_pow_le (a := 1) (b := m) hm
        have h2 : (1 : ℚ) < 2 := by norm_num
        have h3 : (2 : ℚ) ^ 1 = 2 := by norm_num
        linarith
      have hv : geoValue k = 1 := by simp [geoValue, hk0]
      show geoTerm m k = 0
      simp only [geoTerm, hv, if_neg (show ¬((1 : ℚ) ≥ (2 : ℚ) ^ m) from by linarith)]
    · have hlt : ((k : ℕ) - 1) < m := by omega
      have h2 : (2 : ℚ) ^ (k - 1) < (2 : ℚ) ^ m := two_pow_lt hlt
      have hv : geoValue k = (2 : ℚ) ^ (k - 1) := by
        simp [geoValue, show k ≠ 0 from by omega]
      show geoTerm m k = 0
      simp only [geoTerm, hv, if_neg (show ¬((2 : ℚ) ^ (k - 1) ≥ (2 : ℚ) ^ m) from by linarith)]
  -- f m = 0（2^{m-1} < 2^m）；f(m+1) = 2^m（恰踩线）；f(m+2) = 2^{m+1}
  have f0 : geoTerm m m = 0 := by
    have hlt : ((m : ℕ) - 1) < m := by omega
    have h2 : (2 : ℚ) ^ (m - 1) < (2 : ℚ) ^ m := two_pow_lt hlt
    have hv : geoValue m = (2 : ℚ) ^ (m - 1) := by
      simp [geoValue, show m ≠ 0 from by omega]
    show geoTerm m m = 0
    simp only [geoTerm, hv, if_neg (show ¬((2 : ℚ) ^ (m - 1) ≥ (2 : ℚ) ^ m) from by linarith)]
  have f1 : geoTerm m (m + 1) = (2 : ℚ) ^ m := by
    have hv : geoValue (m + 1) = (2 : ℚ) ^ m := by
      simp [geoValue]
    show geoTerm m (m + 1) = 2 ^ m
    simp only [geoTerm, hv, if_pos (le_refl _)]
  have hm2 : (2 : ℚ) ^ (m + 1) = 2 * (2 : ℚ) ^ m := by rw [pow_succ, mul_comm]
  have f2 : geoTerm m (m + 2) = (2 : ℚ) ^ (m + 1) := by
    have hv : geoValue (m + 2) = (2 : ℚ) ^ (m + 1) := by
      simp [geoValue]
    have hle : (2 : ℚ) ^ m ≤ (2 : ℚ) ^ (m + 1) := by
      rw [hm2]
      have h0 : (0 : ℚ) < 2 ^ m := two_pow_pos m
      nlinarith
    show geoTerm m (m + 2) = 2 ^ (m + 1)
    simp only [geoTerm, hv, if_pos hle]
  rw [head, f0, f1, f2, hm2]
  -- (2^m + 2·2^m) / 2^{m+2} = 3/4
  have hm3 : (2 : ℚ) ^ (m + 2) = 2 * (2 : ℚ) ^ (m + 1) := by rw [pow_succ, mul_comm]
  have hne : (2 : ℚ) ^ m ≠ 0 := ne_of_gt (two_pow_pos m)
  have hn4 : (2 : ℚ) ^ (m + 2) = 4 * 2 ^ m := by
    rw [pow_succ, pow_succ]
    ring
  rw [show (0 : ℚ) + 0 + 2 ^ m + 2 * 2 ^ m = 3 * 2 ^ m from by ring, hn4]
  have hpos : (0 : ℚ) < 4 * 2 ^ m := by positivity
  rw [div_eq_div_iff hpos.ne' (by norm_num : (4 : ℚ) ≠ 0)]
  ring
