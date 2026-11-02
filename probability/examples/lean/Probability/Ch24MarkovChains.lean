import Mathlib.Tactic

/-!
# 第 24 章：Markov 链的有限精确账

转移矩阵用 `Fin n → Fin n → ℚ` 的显式函数表示（行随机）。这里不依赖测度论：
平稳分布、n 步转移（Chapman–Kolmogorov 的矩阵乘法形式）、两状态链 `Pⁿ` 的闭式、
细致平衡都是**有理数代数恒等式**，用 `norm_num` / `field_simp` / `ring` / 归纳直接验证。
-/

namespace Ch24

/-- 2×2 与 3×3 矩阵乘法（显式展开，避免 `Matrix` 的实例解析）。 -/
def mul2 (A B : Fin 2 → Fin 2 → ℚ) : Fin 2 → Fin 2 → ℚ :=
  fun i j => A i 0 * B 0 j + A i 1 * B 1 j

def mul3 (A B : Fin 3 → Fin 3 → ℚ) : Fin 3 → Fin 3 → ℚ :=
  fun i j => A i 0 * B 0 j + A i 1 * B 1 j + A i 2 * B 2 j

/-- 两状态链 `[[4/5,1/5],[3/10,7/10]]`。 -/
def P2 : Fin 2 → Fin 2 → ℚ := ![![4/5, 1/5], ![3/10, 7/10]]

/-- 生灭链 `[[1/2,1/2,0],[1/4,1/2,1/4],[0,1/2,1/2]]`。 -/
def P3 : Fin 3 → Fin 3 → ℚ := ![![1/2, 1/2, 0], ![1/4, 1/2, 1/4], ![0, 1/2, 1/2]]

/-- 2 步转移矩阵的四个元素。 -/
theorem two_step :
    mul2 P2 P2 0 0 = 7/10 ∧ mul2 P2 P2 0 1 = 3/10 ∧
    mul2 P2 P2 1 0 = 9/20 ∧ mul2 P2 P2 1 1 = 11/20 := by
  simp [mul2, P2]
  norm_num

/-- 平稳分布 `π = (3/5, 2/5)`：`πP = π` 且总和为 1。 -/
theorem two_state_stationary :
    (3/5 : ℚ) * (4/5) + (2/5) * (3/10) = 3/5 ∧
    (3/5 : ℚ) * (1/5) + (2/5) * (7/10) = 2/5 ∧
    (3/5 : ℚ) + 2/5 = 1 := by
  norm_num

/-- 一般两状态链 `P = [[1−a, a],[b, 1−b]]`：`p_n := P(X_n = 0 | X_0 = 0)`
    满足 `p_{n+1} = b + (1−a−b) p_n`，闭式 `p_n = b/(a+b) + (1−a−b)^n · a/(a+b)`。 -/
def pn (a b : ℚ) : ℕ → ℚ
  | 0 => 1
  | n + 1 => b + (1 - a - b) * pn a b n

theorem pn_closed (a b : ℚ) (h : a + b ≠ 0) (n : ℕ) :
    pn a b n = b / (a + b) + (1 - a - b) ^ n * (a / (a + b)) := by
  induction n with
  | zero => simp only [pn]; field_simp; ring
  | succ n ih =>
    simp only [pn, ih]
    field_simp
    ring

/-- 代入 `a = 1/5, b = 3/10`：`p_n = 3/5 + (1/2)^n · 2/5`，取 n=2 与矩阵乘法的 `7/10` 对账。 -/
theorem pn_n2 : pn (1/5) (3/10) 2 = 7/10 := by
  simp [pn]; norm_num

/-- 生灭链：平稳分布 `π = (1/4, 1/2, 1/4)` 满足 `πP = π`。 -/
theorem birth_death_stationary :
    (1/4 : ℚ) * (1/2) + (1/2) * (1/4) + (1/4) * 0 = 1/4 ∧
    (1/4 : ℚ) * (1/2) + (1/2) * (1/2) + (1/4) * (1/2) = 1/2 ∧
    (1/4 : ℚ) * 0 + (1/2) * (1/4) + (1/4) * (1/2) = 1/4 := by
  norm_num

/-- 细致平衡 `π_i P_ij = π_j P_ji` 在所有 (i,j) 上成立。 -/
theorem birth_death_detailed_balance :
    ∀ i j : Fin 3, ![(1/4 : ℚ), 1/2, 1/4] i * P3 i j = ![(1/4 : ℚ), 1/2, 1/4] j * P3 j i := by
  intro i j
  fin_cases i <;> fin_cases j <;> norm_num [P3]

/-- 3 步转移矩阵 = P² · P（Chapman–Kolmogorov），例：`P³₀₀ = 3/8 + 1/8·... = 9/32`……直接算。 -/
theorem three_step_00 : mul3 (mul3 P3 P3) P3 0 0 = 5/16 := by
  simp [mul3, P3]
  norm_num

/-- Chapman–Kolmogorov：`P²·P = P·P²`（矩阵幂可交换）在 3×3 生灭链上逐元素成立。 -/
theorem ck_assoc : ∀ i j : Fin 3, mul3 (mul3 P3 P3) P3 i j = mul3 P3 (mul3 P3 P3) i j := by
  intro i j
  fin_cases i <;> fin_cases j <;> simp [mul3, P3] <;> norm_num

end Ch24
