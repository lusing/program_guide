import Mathlib

/-!
# Ch05 Laplace 方程 III：Dirichlet 原理的代数核（配方法）

对应书 §2.2.5（能量方法：唯一性的能量证明、Dirichlet 原理）。
书 p.43 的论证结构：能量泛函的一阶变分在解处为零、二阶变分恒正
（凸性），故解是严格极小。本文件把这一结构的**有限维核**完整证出：

对特征基截断（有限指标集 ι，"刚度" λᵢ > 0 与"载荷" fᵢ 给定），
能量 E(v) = Σ (λᵢ/2)(vᵢ)² − Σ fᵢvᵢ 在 cᵢ = fᵢ/λᵢ 处取极小，且

    E(v) − E(c) = Σ (λᵢ/2)(vᵢ − cᵢ)² ≥ 0——

配方法（completing the square）逐项成立。这正是 ch8 变分直接法
与 Lax–Milgram（29 章）的离散原型。
-/

open Finset

namespace Evanspde.Ch05

variable {ι : Type*} [Fintype ι] (lam : ι → ℝ) (f : ι → ℝ)

/-- Rayleigh–Ritz 能量泛函（有限维截断）。 -/
noncomputable def rrEnergy (v : ι → ℝ) : ℝ :=
  ∑ i, (lam i / 2) * (v i)^2 - ∑ i, f i * v i

/-- **配方法恒等式**：任意 v 与极小点 c = f/λ 的能量差恰是
Σ (λ/2)(v−c)²——逐项平方和。 -/
theorem rrEnergy_diff (hlam : ∀ i, 0 < lam i) (v : ι → ℝ) :
    rrEnergy lam f v - rrEnergy lam f (fun i => f i / lam i)
      = ∑ i, (lam i / 2) * (v i - f i / lam i)^2 := by
  have key : ∀ i : ι,
      (lam i / 2) * (v i)^2 - f i * v i
        - ((lam i / 2) * (f i / lam i)^2 - f i * (f i / lam i))
        = (lam i / 2) * (v i - f i / lam i)^2 := by
    intro i
    have hpos := hlam i
    field_simp
    ring
  rw [rrEnergy, rrEnergy, ← sum_sub_distrib, ← sum_sub_distrib, ← sum_sub_distrib,
    sum_congr rfl (fun i _ => key i)]

/-- **Dirichlet 原理（离散核）**：cᵢ = fᵢ/λᵢ 使能量极小。 -/
theorem rrEnergy_minimal (hlam : ∀ i, 0 < lam i) (v : ι → ℝ) :
    rrEnergy lam f (fun i => f i / lam i) ≤ rrEnergy lam f v := by
  have h := rrEnergy_diff lam f hlam v
  have hp : ∀ i, (0:ℝ) ≤ (lam i / 2) * (v i - f i / lam i)^2 := fun i =>
    mul_nonneg (div_nonneg (hlam i).le two_pos.le) (sq_nonneg _)
  have hpos : 0 ≤ ∑ i, (lam i / 2) * (v i - f i / lam i)^2 := sum_nonneg (fun i _ => hp i)
  have hge : rrEnergy lam f v - rrEnergy lam f (fun i => f i / lam i) ≥ 0 := by
    rw [h]; exact hpos
  linarith

/-- 极小点唯一（λ > 0 时能量严格凸）。 -/
theorem rrEnergy_unique (hlam : ∀ i, 0 < lam i) (v : ι → ℝ)
    (hv : rrEnergy lam f v = rrEnergy lam f (fun i => f i / lam i)) :
    v = fun i => f i / lam i := by
  have h := rrEnergy_diff lam f hlam v
  rw [hv, sub_self] at h
  have hzero : ∑ i, (lam i / 2) * (v i - f i / lam i)^2 = 0 := by linarith [h]
  funext i
  have hterm := (sum_eq_zero_iff_of_nonneg
    (fun j _ => mul_nonneg (div_nonneg (hlam j).le two_pos.le) (sq_nonneg _))).mp hzero i
    (mem_univ i)
  rcases mul_eq_zero.mp hterm with h1 | h2
  · -- lam i / 2 = 0 与 lam i > 0 矛盾
    have : lam i = 0 := by
      rcases div_eq_zero_iff.mp h1 with h3 | h4
      · exact h3
      · exact absurd h4 two_ne_zero
    exact absurd this (hlam i).ne'
  · exact sub_eq_zero.mp (sq_eq_zero_iff.mp h2)

end Evanspde.Ch05
