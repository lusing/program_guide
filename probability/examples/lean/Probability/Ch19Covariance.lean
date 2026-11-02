import Mathlib.Tactic

/-!
# 第 19 章 协方差、相关与独立（Lean）

协方差的代数恒等式（在 ℚ 上以 `ring` 判决）、方差和公式、二次型配方
（相关系数界的代数内核）、投资组合最小方差权重，以及“不相关但不独立”的
有限反例 {(−1,1),(0,0),(1,1)}（`norm_num` / `decide`）。无 sorry。
-/

/-! ## 代数恒等式 -/

/-- **协方差捷径**：E[(X−a)(Y−b)] = E[XY] − ab，其中 a=E[X]，b=E[Y]；
这里把 E 的线性性展开成以 m=E[XY]、a、b 表示的代数式。 -/
example (m a b : ℚ) : (m - a * b - a * b + a * b) = m - a * b := by ring

/-- **方差和公式**：Var(X+Y) = Var X + Var Y + 2 Cov(X,Y)。 -/
example (vx vy c : ℚ) : vx + vy + 2 * c = (vx + c) + (vy + c) := by ring

/-- **双线性**：Cov(aX+b, cY+d) = ac Cov(X,Y)（常数 b、d 被中心化抵消）。
设 E[X]=μ, E[Y]=ν, E[XY]=m，则 E[(aX+b)(cY+d)] − E[aX+b]E[cY+d]。 -/
example (a b c d μ ν m : ℚ) :
    (a * c * m + a * d * μ + b * c * ν + b * d) - (a * μ + b) * (c * ν + d)
      = a * c * (m - μ * ν) := by ring

/-- **三项和的方差**：(w₁,w₂,w₃) 组合的 wᵀΣw 展开。 -/
example (w1 w2 w3 s11 s22 s33 s12 s13 s23 : ℚ) :
    w1 * (w1 * s11 + w2 * s12 + w3 * s13)
      + w2 * (w1 * s12 + w2 * s22 + w3 * s23)
      + w3 * (w1 * s13 + w2 * s23 + w3 * s33)
    = w1 ^ 2 * s11 + w2 ^ 2 * s22 + w3 ^ 2 * s33
      + 2 * (w1 * w2 * s12 + w1 * w3 * s13 + w2 * w3 * s23) := by ring

/-! ## 半正定与 |ρ| ≤ 1 的代数内核 -/

/-- **配方**：σ²x² + 2ρστxy + τ²y² = (σx + ρτy)² + (1−ρ²)τ²y²。 -/
example (σ τ ρ x y : ℚ) :
    σ ^ 2 * x ^ 2 + 2 * ρ * σ * τ * x * y + τ ^ 2 * y ^ 2
      = (σ * x + ρ * τ * y) ^ 2 + (1 - ρ ^ 2) * τ ^ 2 * y ^ 2 := by ring

/-- **|ρ| ≤ 1**：若对所有 t 有 va·t² + 2c·t + vb ≥ 0 且 va>0，则 c² ≤ va·vb
（取 t = −c/va，见正文判别式推导）。 -/
example (va vb c : ℚ) (hva : 0 < va)
    (h : ∀ t : ℚ, 0 ≤ va * t ^ 2 + 2 * c * t + vb) : c ^ 2 ≤ va * vb := by
  have := h (-c / va)
  have hne : va ≠ 0 := ne_of_gt hva
  have key : va * (-c / va) ^ 2 + 2 * c * (-c / va) + vb = (va * vb - c ^ 2) / va := by
    field_simp; ring
  rw [key] at this
  have h2 : 0 ≤ va * vb - c ^ 2 := by
    by_contra hneg
    have hneg' : va * vb - c ^ 2 < 0 := by linarith
    have : (va * vb - c ^ 2) / va < 0 := div_neg_of_neg_of_pos hneg' hva
    linarith
  linarith

/-! ## 投资组合 -/

/-- 两资产组合方差 Var(w) = w²s₁ + (1−w)²s₂ + 2w(1−w)c（s₁=σ₁², s₂=σ₂², c=ρσ₁σ₂）。 -/
def portVar (s1 s2 c w : ℚ) : ℚ := w ^ 2 * s1 + (1 - w) ^ 2 * s2 + 2 * w * (1 - w) * c

/-- **最小方差权重** w* = (s₂ − c)/(s₁ + s₂ − 2c)：对任意 w，
Var(w) − Var(w*) = (s₁+s₂−2c)(w − w*)² ≥ 0（这里验证恒等式）。 -/
example (s1 s2 c w : ℚ) (hd : s1 + s2 - 2 * c ≠ 0) :
    portVar s1 s2 c w - portVar s1 s2 c ((s2 - c) / (s1 + s2 - 2 * c))
      = (s1 + s2 - 2 * c) * (w - (s2 - c) / (s1 + s2 - 2 * c)) ^ 2 := by
  unfold portVar
  field_simp
  ring

/-- **数值**：σ₁=.2, σ₂=.3, ρ=.5 ⇒ s₁=1/25, s₂=9/100, c=3/100；w*=6/7，Var*=27/700。 -/
example : (9 / 100 - 3 / 100 : ℚ) / (1 / 25 + 9 / 100 - 2 * (3 / 100)) = 6 / 7 := by
  norm_num

example : portVar (1 / 25) (9 / 100) (3 / 100) (6 / 7) = 27 / 700 := by
  unfold portVar; norm_num

/-- **ρ = −1 的完全对冲**：c=−σ₁σ₂，w=σ₂/(σ₁+σ₂) 时方差 0（σ₁=1/5, σ₂=3/10）。 -/
example : portVar (1 / 25) (9 / 100) (-(3 / 50)) (3 / 5) = 0 := by
  unfold portVar; norm_num

/-! ## 不相关但不独立的有限反例 -/

/-- 反例分布：X ∈ {−1,0,1} 均匀，Y = X²。以 (x,y) ↦ 概率 的函数表示。 -/
def cex : ℤ → ℤ → ℚ
  | -1, 1 => 1 / 3
  | 0, 0 => 1 / 3
  | 1, 1 => 1 / 3
  | _, _ => 0

/-- 总质量为 1（在 x,y ∈ [−1,1] 上求和）。 -/
example : ∑ x ∈ Finset.Icc (-1 : ℤ) 1, ∑ y ∈ Finset.Icc (-1 : ℤ) 1, cex x y = 1 := by
  decide +kernel

/-- E[X]=0, E[Y]=2/3, E[XY]=0 ⇒ Cov = 0。 -/
example : ∑ x ∈ Finset.Icc (-1 : ℤ) 1, ∑ y ∈ Finset.Icc (-1 : ℤ) 1,
    (x * y : ℚ) * cex x y = 0 := by
  decide +kernel

example : ∑ x ∈ Finset.Icc (-1 : ℤ) 1, ∑ y ∈ Finset.Icc (-1 : ℤ) 1,
    (x : ℚ) * cex x y = 0 := by
  decide +kernel

/-- **不独立**：P(X=0, Y=0) = 1/3，而 P(X=0)·P(Y=0) = (1/3)(1/3) = 1/9。 -/
example : cex 0 0 ≠ (1 / 3) * (1 / 3) := by
  simp [cex]

/-- **二值变量的特例**：Cov = 0 ⇒ P(1,1) = p₁p₂，其余三格随之成为边际积。 -/
example (p1 p2 p11 : ℚ) (h : p11 = p1 * p2) :
    (p1 - p11 = p1 * (1 - p2)) ∧ (p2 - p11 = (1 - p1) * p2)
      ∧ (1 - p1 - p2 + p11 = (1 - p1) * (1 - p2)) := by
  subst h
  refine ⟨?_, ?_, ?_⟩ <;> ring
