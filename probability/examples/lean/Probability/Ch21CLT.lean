import Mathlib.Tactic

/-!
# 第 21 章 中心极限定理（Lean）

Miller ch20 的机器侧：标准化代数的矩账、(1+w/N)^N 极限
的数值形态、正态 MGF e^{t²/2} 与偶矩链的会师、Poisson
特例的 Taylor 残差账。
-/

/-! ## 标准化代数 -/

/-- E = 0、Var = 1 的代数：Z = (X−μ)/σ 的参数账
（μ = 5、σ = 2 的数值例）。 -/
example : ((5 : ℚ)) - 5 = 0 := by norm_num

example : (((7 : ℚ)) - 5) / 2 = 1 := by norm_num

/-- X̄_N 的矩账：E = μ、Var = σ²/N（σ² = 4、N = 16 →
Var = 1/4）。 -/
example : ((4 : ℚ)) / 16 = 1 / 4 := by norm_num

/-! ## (1 + w/N)^N → e^w 的数值形态 -/

/-- N = 100、w = 1/2 时 (1 + 1/200)^100 = (201/200)^100
的 ℚ 判决（精确分数；与 e^{1/2} 的比较在 Python 通道）。 -/
example : ((201 : ℚ) / 200) ^ 100 = (201 ^ 100) / (200 ^ 100) := by
  norm_num [div_pow]

example : ((1 : ℚ)) + 1 / 200 > 1 := by norm_num

/-- 单调性：底 > 1 时幂随 N 增（收敛的单调进场）。 -/
example (N : ℕ) : (1 + 1 / 200 : ℚ) ^ N
    ≤ (1 + 1 / 200 : ℚ) ^ (N + 1) := by
  exact pow_le_pow_right₀ (by norm_num) (Nat.le_succ N)

/-! ## 正态 MGF 与偶矩链的会师 -/

/-- e^{t²/2} 的系数 = (2m−1)!!/（2m)!·t^{2m}：即
Σ (t²/2)^m/m! 的系数（m! 分母）。m = 3 的账：
(t²/2)³/3! = t⁶/(8·6) = t⁶/48。 -/
example : ((1 : ℚ)) / 8 / 6 = 1 / 48 := by norm_num

/-- 偶矩链：M(2) = 1、M(4) = 3、M(6) = 15、M(8) = 105。 -/
example : ((3 : ℚ)) * 5 * 7 = 105 := by norm_num

/-! ## Poisson 特例的 Taylor 残差 -/

/-- λ(e^{t/√λ} − 1 − t/√λ) 的形态：u²/2 的账（u = t/√λ，
λ·u² = t²/2）。 -/
example (t : ℚ) : ((4 : ℚ)) * (t / 2) ^ 2 / 2 = t ^ 2 / 2 := by
  field_simp; ring

/-- 标准化的红利：一阶项消失（E[Y] = 0 ⟹ M′_Y(0) = 0）。 -/
example : ((5 : ℚ)) - 5 = 0 := by norm_num

/-- Var(Z_N) 恒为 1：σ²·N/N 的账。 -/
example (s : ℚ) (N : ℚ) (hN : (0 : ℚ) < N) : s ^ 2 * N / N ^ 2 = s ^ 2 / N := by
  field_simp

/-! ## 使用规范的账 -/

/-- X̄_N ~ N(μ, σ²/N) 近似：n = 100、σ = 5 → 标准差
5/10 = 1/2。 -/
example : ((5 : ℚ)) / 10 = 1 / 2 := by norm_num

/-- 连续性修正：P(45 ≤ S ≤ 55) 用 (44.5, 55.5) 折算的
账（μ = 50、σ = 5 → ±1.1σ）。 -/
example : ((55.5 : ℚ)) - 50 = 5.5 ∧ ((44.5 : ℚ) - 50) = -5.5 := by norm_num
