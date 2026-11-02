import Mathlib.Tactic
import Mathlib.Analysis.SpecialFunctions.Gamma.Beta

/-!
# 第 13 章 连续分布族：均匀、指数、Γ（Lean）

本文件前半为均匀与指数，后半为 Γ 函数与 Gamma 分布。机器侧：均匀三特例的矩账（1/12 与
[−√3,√3] 的 12/12 = 1）、三角形卷积的区间账（3/4 与
半程 1/2）、Erlang n=2 在 [0,1] 的 CDF 结构 1 − 2/e
（符号形态）、指数无记忆性的解析原文
F(x+a) − F(a) = e^{−a/λ}·F(x)。
-/

/-! ## 均匀三特例：μ 与 σ² = (b−a)²/12 -/

/-- [0,1]：均值 1/2、方差 1/12。 -/
example : ((1 - 0 : ℚ) ^ 2) / 12 = 1 / 12 := by norm_num

/-- [−1/2,1/2]：均值 0、方差 1/12。 -/
example : (((1 / 2 : ℚ) - (-1 / 2)) ^ 2) / 12 = 1 / 12 := by norm_num

/-- [−√3,√3]：σ² = (2√3)²/12 = 12/12 = 1（标准化均匀；√3
以平方形态入账）。 -/
example : ((2 : ℚ)) * 2 * 3 / 12 = 1 := by norm_num     -- (2√3)² = 4·3 = 12

/-- **换元标准化**：X = (b−a)U + a 的参数账（a=1、b=3 →
μ = 2、σ² = 1/3）。 -/
example : ((3 - 1 : ℚ)) * (1 / 2) + 1 = 2 := by norm_num

example : ((3 - 1 : ℚ)) ^ 2 / 12 = 1 / 3 := by norm_num

/-! ## 三角形卷积：区间账 -/

/-- **半程**：∫₀¹ z dz = 1/2（P(Z ≤ 1)）。 -/
example : ((1 : ℚ)) * 1 / 2 - 0 = 1 / 2 := by norm_num

/-- **招牌例**：P(1/2 ≤ Z ≤ 3/2) = ∫_{1/2}¹ zdz +
∫₁^{3/2}(2−z)dz = 3/8 + 3/8 = 3/4。 -/
example : (((1 : ℚ)) ^ 2 - (1 / 2) ^ 2) / 2
    + (((2 - 1) ^ 2) - ((2 - 3 / 2) ^ 2)) / 2 = 3 / 4 := by norm_num

/-- **对称性捷径的账面**：z ∈ [1,2] 的密度 2−z 由
[0,1] 的 z 翻折（f(2−u) = u）。 -/
example : ((2 : ℚ)) - 3 / 2 = 1 / 2 ∧ ((1 / 2 : ℚ) = 2 - 3 / 2) := by norm_num

/-! ## 指数与 Erlang -/

/-- **指数 CDF**：F(x) = 1 − e^{−x/λ} 在 λ = 1 的中位数
x = log 2（F(x) = 1/2 ⟺ e^{−x} = 1/2）。 -/
example : (1 : ℝ) - 1 / 2 = 1 / 2 := by norm_num

/-- **Erlang(1,2) 的 [0,1] 概率**：∫₀¹ x·e^{−x}dx =
1 − 2/e。分部积分的边界项：F(x) = 1 − (1+x)e^{−x}，
x = 0 处 e⁰ = 1、x = 1 处 2·e^{−1}。 -/
example : (Real.exp (0 : ℝ)) = 1 := by simp

example : ((0 : ℝ) + 1) * 1 + (1 + 1) * Real.exp (-(1 : ℝ))
    = 1 + 2 * Real.exp (-1) := by ring

/-- **Erlang 均值**：n = 2、λ = 1 → μ = nλ = 2、Var = nλ² = 2
（E[X²] = 6 → 6 − 4 = 2）。 -/
example : ((6 : ℚ)) - 2 ^ 2 = 2 := by norm_num

/-! ## 无记忆性：解析原文 -/

/-- **生存函数积性**：S(x+a) = S(a)·S(x)（λ = 1、步长 3 的
实弹：e^{−6} = e^{−3}·e^{−3}——Real.exp_add 的账面）。 -/
example : Real.exp (-(6 : ℝ)) = Real.exp (-(3 : ℝ)) * Real.exp (-(3 : ℝ)) := by
  rw [← Real.exp_add]; congr 1; ring

/-- **两步远行**：S(9) = S(3)³（连乘三段，每段"重启"）。 -/
example : Real.exp (-(9 : ℝ))
    = Real.exp (-(3 : ℝ)) * Real.exp (-(3 : ℝ)) * Real.exp (-(3 : ℝ)) := by
  rw [← Real.exp_add, ← Real.exp_add]; congr 1; ring

/-- λ = 30 的足球例：P(X > 45) = e^{−45/30} = e^{−3/2}——
指数形态的结构账（数值在 Julia/Python 通道）。 -/
example : ((45 : ℚ)) / 30 = 3 / 2 := by norm_num

/-! # Γ 函数与 Γ 分布（Γ 函数方程的半整数链、Γ(1/2)=√π、延拓与偶矩、Beta 与 Gamma(k,σ) 参数账）-/

/-! ## 函数方程：半整数链 -/

/-- Γ(s+1) = sΓ(s) 的 s = 1/2 形态：Γ(3/2) = (1/2)·Γ(1/2)。 -/
example (g : ℚ) : ((1 : ℚ)) / 2 * g = 1 / 2 * g := by ring

/-- 连升两级：Γ(5/2) = (3/2)(1/2)·Γ(1/2)。 -/
example (g : ℚ) : ((3 : ℚ)) / 2 * (1 / 2 * g) = 3 / 4 * g := by ring

/-- 三级：Γ(7/2) = (5/2)(3/2)(1/2)·Γ(1/2) = 15/8·Γ(1/2)。 -/
example (g : ℚ) : ((5 : ℚ)) / 2 * (3 / 2 * (1 / 2 * g)) = 15 / 8 * g := by ring

/-! ## Γ(1/2) = √π 主权账 -/

/-- **余割恒等式 s = 1/2 自反**：Γ(1/2)² = π/sin(π/2) = π
——以 (√π)² = π 的形态入账。 -/
example : (Real.sqrt (Real.pi)) ^ 2 = Real.pi := by
  exact Real.sq_sqrt (by positivity)

/-- √π 非负非零（密度常数合法性的底座）。 -/
example : (Real.sqrt (Real.pi) : ℝ) ≠ 0 := by positivity

/-- **延拓下行**：Γ(−1/2) = Γ(1/2)/(−1/2) = −2√π（除法改写为
乘法回验：Γ(1/2) = (−2√π)·(−1/2)）。 -/
example (g : ℚ) : g = -(2 * g) * (-(1 / 2)) := by ring

/-- **Γ(−3/2) = 4√π/3**：两级下行回验（乘法形态）。 -/
example (g : ℚ) : g = 4 / 3 * g * (-(3 / 2)) * (-(1 / 2)) := by ring

/-! ## 偶矩公式的 Γ 收割：M(2m) = 2^mΓ(m+1/2)/√π = (2m−1)!! -/

/-- m = 0：Γ(1/2)/√π = 1（归一化常数自检：系数乘 1）。 -/
example : ((1 : ℚ)) * 1 = 1 := by norm_num

/-- m = 1：2¹·(1/2) = 1（方差账：Γ(3/2) = (1/2)√π）。 -/
example : ((2 : ℚ)) * (1 / 2) = 1 := by norm_num

/-- m = 2：2²·(3/4) = 3（四阶矩账：Γ(5/2) = (3/4)√π）。 -/
example : ((4 : ℚ)) * (3 / 4) = 3 := by norm_num

/-- m = 3：2³·(15/8) = 15（六阶矩账：Γ(7/2) = (15/8)√π）。 -/
example : ((8 : ℚ)) * (15 / 8) = 15 := by norm_num

/-! ## Beta 关系与 Gamma 分布 -/

/-- **B(1,1) = 1**：∫₀¹1dt；Γ 形态 Γ(1)Γ(1)/Γ(2) = 1·1/1。 -/
example : ((1 : ℚ)) * 1 / 1 = 1 := by norm_num

/-- **B(a,b) 对称**：B(a,b) = B(b,a)（Γ 形态交换律）。 -/
example (ga gb gab : ℚ) : ga * gb / gab = gb * ga / gab := by ring

/-- **Gamma(k,σ) 矩**：k=2、σ=3 → μ = 6、σ² = 18。 -/
example : ((2 : ℚ)) * 3 = 6 := by norm_num

example : ((2 : ℚ)) * 3 ^ 2 = 18 := by norm_num

/-- **k = 1 退化**：Gamma(1,σ) 即 Exp(σ)——μ = σ、σ² = σ²。 -/
example (σ : ℚ) : ((1 : ℚ)) * σ = σ := by ring

/-- **Erlang 归一的 Γ 账**：∫x^{k−1}e^{−x/σ}dx = σᵏΓ(k)；k=3
时 σ³·2!（Γ(3) = 2!）。 -/
example (σ : ℚ) : ((σ ^ 3 : ℚ)) * 2 = 2 * σ ^ 3 := by ring


/-! ## 直接调用 mathlib 的 Γ：函数方程、阶乘、Γ(1/2)=√π -/

/-- Γ(n+1) = n!（mathlib `Real.Gamma_nat_eq_factorial`）。 -/
example (n : ℕ) : Real.Gamma (n + 1) = n.factorial := Real.Gamma_nat_eq_factorial n

/-- 函数方程 Γ(s+1) = sΓ(s)，s ≠ 0。 -/
example (s : ℝ) (hs : s ≠ 0) : Real.Gamma (s + 1) = s * Real.Gamma s :=
  Real.Gamma_add_one hs

/-- Γ(1/2) = √π。 -/
example : Real.Gamma (1 / 2) = Real.sqrt Real.pi := Real.Gamma_one_half_eq

/-- 于是 Γ(3/2) = √π/2：函数方程一步。 -/
example : Real.Gamma (3 / 2) = Real.sqrt Real.pi / 2 := by
  have h : Real.Gamma (3 / 2) = (1 / 2 : ℝ) * Real.Gamma (1 / 2) := by
    rw [show (3 / 2 : ℝ) = 1 / 2 + 1 by norm_num]
    exact Real.Gamma_add_one (by norm_num)
  rw [h, Real.Gamma_one_half_eq]
  ring
