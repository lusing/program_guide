import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Probability.Independence.Basic

/-!
# 第 59 章 随机游动与马氏链（Lean）

胡书 §8.1 的机器侧。mathlib 无马氏链 API（4.33），按通道分工自建
有限精确账：

- **赌徒破产的唯一性全证**：二阶差分为零 ⟹ 相邻差恒等 ⟹ 解线性
  ⟹ 边界结算 f i = i/N（正文 59.8 差分方程路的完整机器化）；
- **通信链转移阵的幂**：P² 与显式公式在有理数上精确核对——
  Chapman–Kolmogorov 的矩阵语义（正文 59.6）；
- iid 增量的形式锚点（ProbabilityTheory.iid）。
-/

open MeasureTheory

#check @ProbabilityTheory.iIndepFun
-- iid（独立同分布）函数列的形式名（游动 = 部分和，正文 59.1 的机器化身）

/-! ## 赌徒破产：调和方程解的唯一性（f i = i/N） -/

/-- **破产概率的唯一性**（正文 59.8）：f 满足边界 f 0 = 0、f N = 1
与内部调和性 2·f i = f(i−1) + f(i+1)，则必为 f i = i/N。
证明三步：相邻差恒等（归纳）⟹ 解线性（归纳）⟹ 边界结算。 -/
theorem gambler_ruin_unique (N : ℕ) (hN : 0 < N) (f : ℕ → ℚ)
    (h0 : f 0 = 0) (hNf : f N = 1)
    (hrec : ∀ i, 0 < i → i < N → 2 * f i = f (i - 1) + f (i + 1)) :
    ∀ i, i ≤ N → f i = (i : ℚ) / (N : ℚ) := by
  -- 第一步：调和性改写为"相邻差不变"：d(k+1) = d(k)
  have dstep : ∀ k, k + 1 < N → f (k + 2) - f (k + 1) = f (k + 1) - f k := by
    intro k hk
    have h := hrec (k + 1) (by omega) (by omega)
    have e1 : k + 1 - 1 = k := by omega
    have e2 : k + 1 + 1 = k + 2 := by omega
    rw [e1, e2] at h
    linarith
  -- 第二步：一切相邻差都等于 d(0) = f 1 − f 0
  have dconst : ∀ k, k < N → f (k + 1) - f k = f 1 - f 0 := by
    intro k
    induction k with
    | zero => intro _; rfl
    | succ n ih =>
      intro hk
      exact (dstep n (by omega)).trans (ih (by omega))
  -- 第三步：解线性：f m − f 0 = m · (f 1 − f 0)
  have linear : ∀ m, m ≤ N → f m - f 0 = (m : ℚ) * (f 1 - f 0) := by
    intro m
    induction m with
    | zero => simp
    | succ n ih =>
      intro hn
      have h1 := ih (Nat.le_of_succ_le hn)
      have h2 := dconst n (by omega)
      have split : f (n + 1) - f 0 = (f (n + 1) - f n) + (f n - f 0) := by ring
      rw [split, h2, h1]
      push_cast
      ring
  -- 结算：边界定出公差，再回代
  have fN := linear N (le_refl N)
  rw [hNf, h0] at fN
  simp only [sub_zero] at fN
  -- fN : 1 = ↑N * f 1（f 0 = 0 已代入）
  have hNq : ((N : ℕ) : ℚ) ≠ 0 := by
    exact_mod_cast (Nat.pos_iff_ne_zero.1 hN)
  have hc : f 1 - f 0 = 1 / ((N : ℕ) : ℚ) := by
    rw [h0]
    simp only [sub_zero]
    field_simp
    linarith
  intro i hi
  have h := linear i hi
  rw [hc] at h
  rw [h0] at h
  simp only [sub_zero] at h
  -- h : f i = ↑i * (1 / ↑N)
  rw [one_div] at h
  rw [div_eq_mul_inv]
  exact h

/-! ## 通信链转移阵的幂（Chapman–Kolmogorov 的矩阵语义） -/

/-- 通信链（例 8.1.1，p = 3/4）：保持概率 3/4、翻转概率 1/4。 -/
def commP : Matrix (Fin 2) (Fin 2) ℚ :=
  !![(3 : ℚ) / 4, 1 / 4; 1 / 4, 3 / 4]

/-- P² 的显式核对：对角元 5/8 = (1 + q²)/2（q = 2p − 1 = 1/2），
非对角元 3/8 = (1 − q²)/2——记忆衰减率 q² 的两步版。 -/
example : commP * commP = !![(5 : ℚ) / 8, 3 / 8; 3 / 8, 5 / 8] := by
  ext i j
  fin_cases i <;> fin_cases j <;>
    simp [Matrix.mul_apply, commP, Fin.sum_univ_two] <;> norm_num

/-- 显式公式的参数账：(1 + q²)/2 = 5/8 与 (1 − q²)/2 = 3/8
（q = 1/2），即 P^(2) 与闭式解一致。 -/
example : ((1 : ℚ) + (1 / 2) ^ 2) / 2 = 5 / 8 ∧ ((1 : ℚ) - (1 / 2) ^ 2) / 2 = 3 / 8 := by
  constructor <;> norm_num
