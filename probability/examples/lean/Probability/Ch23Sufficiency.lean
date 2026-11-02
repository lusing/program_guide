import Mathlib.Tactic

/-!
# 第 23 章 充分统计量与数据简化（Lean）

只验证有限、可判定的部分（自洽、无 sorry）：

* Bernoulli 因子分解：f(x;p) = p^T (1-p)^(n-T) 只经 T = Σx 依赖数据，h ≡ 1；
* 给定 T = t 的条件概率 = 1/C(n,t)，与 p 无关（n = 3 逐点核对、一般 n 的分式代数）；
* 对照：T' = x₁ 不充分——P(x₂=1 | x₁=1) = p；
* 最小充分性的前提：似然比与 p 无关 ⇔ 和相同（n = 3，取三个 p 值的有限验证）；
* Rao–Blackwell 的 Bernoulli 例：Var(T/n) = p(1-p)/n。
-/

/-- 一次抽样的 Bernoulli 似然（x ∈ {0,1}）。 -/
def bern (p : ℚ) : Fin 2 → ℚ
  | 0 => 1 - p
  | 1 => p

/-- n = 3 的联合似然。 -/
def lik3 (p : ℚ) (a b c : Fin 2) : ℚ := bern p a * bern p b * bern p c

/-- 因子分解：对 {0,1}³ 中每个点，f(x;p) = g(T, p)·h(x)，g(t,p) = p^t (1-p)^(3-t)，h = 1。 -/
example (p : ℚ) (a b c : Fin 2) :
    lik3 p a b c =
      p ^ (a.val + b.val + c.val) *
        (1 - p) ^ (3 - (a.val + b.val + c.val)) := by
  fin_cases a <;> fin_cases b <;> fin_cases c <;>
    simp only [lik3, bern] <;> ring

/-- 给定 T = 1 的条件概率：三个样本点 (1,0,0), (0,1,0), (0,0,1) 的似然都是 p(1-p)²，
总和 3p(1-p)²，故条件概率 = 1/3（只要 0 < p < 1），与 p 无关。 -/
example (p : ℚ) (hp : p * (1 - p) ^ 2 ≠ 0) :
    lik3 p 1 0 0 / (lik3 p 1 0 0 + lik3 p 0 1 0 + lik3 p 0 0 1) = 1 / 3 := by
  set q : ℚ := p * (1 - p) ^ 2 with hq
  have hq' : q ≠ 0 := hp
  have h1 : lik3 p 1 0 0 = q := by simp only [hq, lik3, bern]; ring
  have h2 : lik3 p 0 1 0 = q := by simp only [hq, lik3, bern]; ring
  have h3 : lik3 p 0 0 1 = q := by simp only [hq, lik3, bern]; ring
  rw [h1, h2, h3]
  have hden : q + q + q = 3 * q := by ring
  rw [hden]
  field_simp [hq']

/-- 给定 T = 2：三个点的似然都是 p²(1-p)，条件概率 = 1/3。 -/
example (p : ℚ) (hp : p ^ 2 * (1 - p) ≠ 0) :
    lik3 p 1 1 0 / (lik3 p 1 1 0 + lik3 p 1 0 1 + lik3 p 0 1 1) = 1 / 3 := by
  set q : ℚ := p ^ 2 * (1 - p) with hq
  have hq' : q ≠ 0 := hp
  have h1 : lik3 p 1 1 0 = q := by simp only [hq, lik3, bern]; ring
  have h2 : lik3 p 1 0 1 = q := by simp only [hq, lik3, bern]; ring
  have h3 : lik3 p 0 1 1 = q := by simp only [hq, lik3, bern]; ring
  rw [h1, h2, h3]
  have hden : q + q + q = 3 * q := by ring
  rw [hden]
  field_simp [hq']

/-- 一般 n 的代数：同一个 T = t 的每个点似然都是 p^t (1-p)^(n-t)，共 C(n,t) 个，
故条件概率 = a / (C·a) = 1/C，其中 a ≠ 0 是公共似然（p 全部约去）。 -/
example (a C : ℚ) (ha : a ≠ 0) (hC : C ≠ 0) : a / (C * a) = 1 / C := by
  field_simp

/-- 具体二项系数：C(3,1) = C(3,2) = 3，C(4,2) = 6。 -/
example : Nat.choose 3 1 = 3 ∧ Nat.choose 3 2 = 3 ∧ Nat.choose 4 2 = 6 := by decide

/-! ## 对照：T' = x₁ 不充分 -/

/-- P(x₂ = 1 | x₁ = 1) = p ·p + p·(1-p)·... 直接算：
联合 x₁=1,x₂=1 的概率 p²，边缘 x₁=1 的概率 p，比值 = p，依赖 p。 -/
example (p : ℚ) (hp : p ≠ 0) : (p * p) / p = p := by
  field_simp

/-- 不同 p 给出不同条件概率，因此该条件分布"含 p"。 -/
example : ((1 : ℚ) / 3) ≠ 3 / 4 := by norm_num

/-! ## 最小充分性的有限验证：似然比与 p 无关 ⇔ 和相同 -/

/-- 和相同（(1,0,0) 与 (0,1,0)）：不同 p 的似然比恒为 1。 -/
example : ∀ p ∈ ({1 / 5, 1 / 2, 4 / 5} : Finset ℚ),
    lik3 p 1 0 0 / lik3 p 0 1 0 = 1 := by
  intro p hp
  simp only [Finset.mem_insert, Finset.mem_singleton] at hp
  rcases hp with rfl | rfl | rfl <;> norm_num [lik3, bern]

/-- 和不同（(1,0,0) 与 (1,1,0)）：似然比 (1-p)/p 随 p 变化，三个 p 值得到三个不同的值。 -/
example : lik3 (1 / 5) 1 0 0 / lik3 (1 / 5) 1 1 0 = 4 ∧
    lik3 (1 / 2) 1 0 0 / lik3 (1 / 2) 1 1 0 = 1 ∧
    lik3 (4 / 5) 1 0 0 / lik3 (4 / 5) 1 1 0 = 1 / 4 := by
  norm_num [lik3, bern]

/-! ## Rao–Blackwell：Bernoulli 例的方差账 -/

/-- Var(X₁) = p(1-p)；T/n 的方差 = n·p(1-p)/n² = p(1-p)/n，缩小到 1/n。 -/
example (p n : ℚ) (hn : n ≠ 0) : n * (p * (1 - p)) / n ^ 2 = p * (1 - p) / n := by
  field_simp

/-- n = 5, p = 1/5：Var(X₁) = 4/25，Var(T/5) = 4/125。 -/
example : (1 / 5 : ℚ) * (1 - 1 / 5) = 4 / 25 ∧
    (1 / 5 : ℚ) * (1 - 1 / 5) / 5 = 4 / 125 := by norm_num
