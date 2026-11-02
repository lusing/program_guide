import Mathlib.Tactic

/-!
# 第 32 章：极大似然估计（Lean）

本文件证明有限参数模型中的得分与信息代数，并把双射重参数化下
MLE 不变性写成一个与具体分布无关的极大值定理。
-/

namespace Ch32

/-- Bernoulli 样本的单参数总得分，其中 `k` 为成功数、`n` 为样本量。 -/
def bernoulliScore (k n p : ℚ) : ℚ := k / p - (n - k) / (1 - p)

/-- 通分后，得分的符号完全由 `k-np` 决定。 -/
theorem bernoulli_score_numerator (k n p : ℚ) (hp : p ≠ 0) (hp1 : 1 - p ≠ 0) :
    bernoulliScore k n p = (k - n * p) / (p * (1 - p)) := by
  simp only [bernoulliScore]
  field_simp
  ring

/-- 一个 Bernoulli 观测在真参数处的得分均值为零。 -/
theorem bernoulli_score_mean (p : ℚ) (hp : p ≠ 0) (hp1 : 1 - p ≠ 0) :
    (1 - p) * bernoulliScore 0 1 p + p * bernoulliScore 1 1 p = 0 := by
  simp only [bernoulliScore]
  field_simp
  ring

/-- 单观测 Fisher 信息为 `1/[p(1-p)]`。 -/
def bernoulliInformation (p : ℚ) : ℚ := 1 / (p * (1 - p))

/-- 得分平方的期望等于期望负曲率，也就是信息等式。 -/
theorem bernoulli_information_equality (p : ℚ) (hp : p ≠ 0) (hp1 : 1 - p ≠ 0) :
    (1 - p) * bernoulliScore 0 1 p ^ 2 + p * bernoulliScore 1 1 p ^ 2 =
      bernoulliInformation p := by
  simp only [bernoulliScore, bernoulliInformation]
  field_simp
  ring

/-- Poisson 对数似然的单观测得分。 -/
def poissonScore (x lam : ℚ) : ℚ := x / lam - 1

/-- 若 `E[X]=lam`，则 Poisson 得分均值为零。 -/
theorem poisson_score_mean (lam : ℚ) (hlam : lam ≠ 0) :
    poissonScore lam lam = 0 := by
  simp only [poissonScore]
  field_simp
  ring

/-- Poisson 的期望负曲率：把 `E[X]=lam` 代入 `E[X]/lam²`。 -/
theorem poisson_information (lam : ℚ) (hlam : lam ≠ 0) :
    lam / lam ^ 2 = 1 / lam := by
  field_simp

/-- 正态模型中，固定 `v=σ²` 后的方差得分。 -/
def normalVarianceScore (n q v : ℚ) : ℚ :=
  -n / (2 * v) + q / (2 * v ^ 2)

/-- 代入 `v=q/n` 后，正态方差得分恰为零；这里 `q=Σ(x_i-x̄)²`。 -/
theorem normal_variance_mle (n q : ℚ) (_hn : n ≠ 0) (hq : q ≠ 0) :
    normalVarianceScore n q (q / n) = 0 := by
  simp only [normalVarianceScore]
  field_simp
  ring

/-- `L` 在集合 `s` 上的极大点定义。 -/
def IsMax {α : Type} (L : α → ℚ) (s : Set α) (a : α) : Prop :=
  a ∈ s ∧ ∀ b ∈ s, L b ≤ L a

/-- 若 `g` 与 `h` 互为反函数，则 `θ̂` 的最大性转化为 `g(θ̂)` 的最大性。 -/
theorem mle_invariance {Θ Γ : Type} (g : Θ → Γ) (h : Γ → Θ)
    (L : Θ → ℚ) (thetaHat : Θ)
    (hg : ∀ theta, h (g theta) = theta)
    (hmax : IsMax L Set.univ thetaHat) :
    IsMax (fun eta => L (h eta)) Set.univ (g thetaHat) := by
  refine ⟨Set.mem_univ _, ?_⟩
  intro eta _
  have bound := hmax.2 (h eta) (Set.mem_univ _)
  dsimp
  rw [hg thetaHat]
  exact bound

end Ch32
