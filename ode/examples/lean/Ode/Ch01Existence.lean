import Mathlib.Analysis.ODE.ExistUnique
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.SpecialFunctions.Sqrt

/-!
# 第 01 章 存在唯一性与 Picard 迭代（Lean）

书 §2.1。mathlib 的 Picard–Lindelöf 全套理论在 `Mathlib.Analysis.ODE`：
- 存在性入口：`ContDiffAt.exists_forall_mem_closedBall_exists_eq_forall_
  mem_Ioo_hasDerivAt₀`（C¹ 向量场有局部解）；
- 唯一性：`ODE_solution_unique_of_mem_Icc_right`（Lipschitz 区域内解唯一）；
- 反例：对 y' = √y、y(0) = 0 直接出示两个解——非唯一性的机器证明。
-/

open Set

section Existence

/-- 存在性（书定理的机器版）：y' = y² 的右端 f(y) = y² 处处 C¹，
故过初值点 (1, 1) 存在局部解——书例 2.1(a) 的"存在"部分。 -/
example : ∃ α : ℝ → ℝ, α 1 = 1 ∧ ∃ ε > (0 : ℝ),
    ∀ t ∈ Ioo (1 - ε) (1 + ε), HasDerivAt α (α t ^ 2) t := by
  have hf : ContDiffAt ℝ 1 (fun x : ℝ => x ^ 2) 1 :=
    ((contDiff_id.pow 2).of_le le_top).contDiffAt
  obtain ⟨α, hα1, ε, hε, hα2⟩ :=
    hf.exists_forall_mem_closedBall_exists_eq_forall_mem_Ioo_hasDerivAt₀ 1
  exact ⟨α, hα1, ε, hε, fun t ht => hα2 t ht⟩

end Existence

section Uniqueness

/-- 平方函数在 [-2, 2] 上 Lipschitz，常数 4：|y² − z²| = |y+z||y−z| ≤ 4|y−z|。
这是"有界偏导 ⟹ Lipschitz"（中值定理）的手工低配版。 -/
lemma sq_lipschitz_on (y z : ℝ) (hy : y ∈ Icc (-2 : ℝ) 2) (hz : z ∈ Icc (-2 : ℝ) 2) :
    |y ^ 2 - z ^ 2| ≤ 4 * |y - z| := by
  obtain ⟨hy1, hy2⟩ := hy
  obtain ⟨hz1, hz2⟩ := hz
  have hy' : |y| ≤ 2 := abs_le.2 ⟨by linarith, by linarith⟩
  have hz' : |z| ≤ 2 := abs_le.2 ⟨by linarith, by linarith⟩
  have hfac : y ^ 2 - z ^ 2 = (y + z) * (y - z) := by ring
  rw [hfac, abs_mul]
  calc |y + z| * |y - z| ≤ (|y| + |z|) * |y - z| :=
        mul_le_mul_of_nonneg_right (abs_add_le y z) (abs_nonneg (y - z))
    _ ≤ 4 * |y - z| := by gcongr; linarith

/-- 唯一性（书例 2.1(a) 的"唯一"部分）：在矩形 |y| ≤ 2 内，
y' = y²、y(1) = 1 的任意两个解在 [1, 3/2] 上一致。 -/
example (f g : ℝ → ℝ)
    (hf : ∀ t ∈ Icc (1 : ℝ) (3 / 2), HasDerivAt f (f t ^ 2) t ∧ f t ∈ Icc (-2 : ℝ) 2)
    (hg : ∀ t ∈ Icc (1 : ℝ) (3 / 2), HasDerivAt g (g t ^ 2) t ∧ g t ∈ Icc (-2 : ℝ) 2)
    (h1 : f 1 = g 1) : EqOn f g (Icc (1 : ℝ) (3 / 2)) := by
  have hlip : ∀ t ∈ Ico (1 : ℝ) (3 / 2),
      LipschitzOnWith 4 (fun y : ℝ => y ^ 2) (Icc (-2 : ℝ) 2) := by
    intro t _
    rw [lipschitzOnWith_iff_dist_le_mul]
    intro y hy z hz
    simp only [Real.dist_eq]
    exact sq_lipschitz_on y z hy hz
  exact ODE_solution_unique_of_mem_Icc_right
    (v := fun _ y => y ^ 2) (s := fun _ => Icc (-2 : ℝ) 2) (K := 4) hlip
    (HasDerivAt.continuousOn (fun t ht => (hf t ht).1))
    (fun t ht => ((hf t (Ico_subset_Icc_self ht)).1).hasDerivWithinAt)
    (fun t ht => (hf t (Ico_subset_Icc_self ht)).2)
    (HasDerivAt.continuousOn (fun t ht => (hg t ht).1))
    (fun t ht => ((hg t (Ico_subset_Icc_self ht)).1).hasDerivWithinAt)
    (fun t ht => (hg t (Ico_subset_Icc_self ht)).2)
    h1

end Uniqueness

section Nonuniqueness

/-- 非唯一性铁证之一：y ≡ 0 是 y' = √y、y(0) = 0 的解。 -/
example : (fun _ : ℝ => (0 : ℝ)) 0 = 0 ∧
    ∀ t : ℝ, HasDerivAt (fun _ : ℝ => (0 : ℝ)) ((0 : ℝ)) t :=
  ⟨rfl, fun t => hasDerivAt_const (c := (0 : ℝ)) (x := t)⟩

/-- 非唯一性铁证之二：y = x²/4 在 x ≥ 0 上也是 y' = √y、y(0) = 0 的解。
两个解同过初值点 (0, 0)——存在唯一性定理的 Lipschitz 条件在这里失效
（√y 在 y = 0 处导数无界），唯一性随之破产。 -/
example (x : ℝ) (hx : 0 ≤ x) :
    HasDerivAt (fun x => x ^ 2 / 4) (Real.sqrt (x ^ 2 / 4)) x := by
  have h1 : HasDerivAt (fun x : ℝ => x ^ 2) (2 * x) x := by
    simpa using hasDerivAt_pow 2 x
  have hderiv : HasDerivAt (fun x => x ^ 2 / 4) (x / 2) x := by
    refine (HasDerivAt.div_const h1 4).congr_deriv ?_
    field_simp
    ring
  have hsqrt : Real.sqrt (x ^ 2 / 4) = x / 2 := by
    have hq : x ^ 2 / 4 = (x / 2) ^ 2 := by ring
    rw [hq, Real.sqrt_sq_eq_abs, abs_of_nonneg (by positivity)]
  rw [hsqrt]
  exact hderiv

/-- 初值点核对：x²/4 过 (0, 0)。 -/
example : (fun x => x ^ 2 / 4 : ℝ → ℝ) 0 = 0 := by norm_num

end Nonuniqueness
