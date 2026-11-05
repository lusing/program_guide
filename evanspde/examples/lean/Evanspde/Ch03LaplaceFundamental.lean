import Mathlib

/-!
# Ch03 Laplace 方程 I：平均值公式的完整机器证明

对应书 §2.2.1–§2.2.2（基本解的导出、定理 2 平均值公式）。本文件
把书定理 2 对**非平凡调和函数** u = x² − y² 完整证出：

* 引理：∫₀^{2π} cos θ dθ = 0 与 ∫₀^{2π} cos 2θ dθ = 0（FTC + 倍角）；
* `mean_value_x2y2`：u 在任意圆周上的积分乘以 1/(2π) 等于圆心值。

结构坑账（Lean）：①多个 `HasDerivAt.add` 嵌套产生 Pi-加法函数形状，
与 λ-体不 defeq-unify——改用**分项积分**，每项单独 FTC；②`Real.sin_sq`
右端是 `cos (x * 2)` 形状，与 `cos (2 * x)` 不语法匹配——倍角一律走
`Real.cos_add`（θ + θ 版本）；③`integral_eq_sub_of_hasDerivAt` 有
可积性副目标，`Continuous.intervalIntegrable 0 (2*π)` 显式喂。
-/

open Real intervalIntegral MeasureTheory

namespace Evanspde.Ch03

/-- sin(4π) = sin(2π + 2π) = 0（只用 sin(2π) = 0、cos(2π) = 1）。 -/
theorem sin_four_pi : sin (2 * (2 * π)) = 0 := by
  have h : 2 * (2 * π) = 2 * π + 2 * π := by ring
  rw [h, Real.sin_add]
  simp [Real.sin_two_pi, Real.cos_two_pi]

/-- ∫₀^{2π} cos θ dθ = 0（原函数 sin，端点 sin(2π) = sin 0 = 0）。 -/
theorem integral_cos_period : ∫ θ in (0 : ℝ)..2 * π, cos θ = 0 := by
  rw [integral_eq_sub_of_hasDerivAt (fun θ _ => hasDerivAt_sin θ)]
  · simp [Real.sin_two_pi, sin_zero]
  · exact continuous_cos.intervalIntegrable 0 (2 * π)

/-- ∫₀^{2π} cos(2θ) dθ = 0（先 ring 同余到链式形状，再 FTC）。 -/
theorem integral_cos2_period : ∫ θ in (0 : ℝ)..2 * π, cos (2 * θ) = 0 := by
  have h : ∀ θ : ℝ,
      HasDerivAt (fun θ => sin (2 * θ) / 2) (cos (2 * θ) * (2 * 1) / 2) θ := fun θ =>
    ((hasDerivAt_sin (2 * θ)).comp θ ((hasDerivAt_id θ).const_mul 2)).div_const 2
  rw [integral_congr (f := fun θ => cos (2 * θ))
      (g := fun θ => cos (2 * θ) * (2 * 1) / 2) (fun θ _ => by ring),
    integral_eq_sub_of_hasDerivAt (fun θ _ => h θ)]
  · rw [sin_four_pi]
    simp
  · exact (by continuity : Continuous (fun θ : ℝ => cos (2 * θ) * (2 * 1) / 2)).intervalIntegrable 0 (2 * π)

/-- **平均值公式（书定理 2 的非平凡实例）**：调和多项式 u = x² − y²
在圆周 {(cₓ+ρcosθ, c_y+ρsinθ)} 上的积分乘以 1/(2π) 等于圆心值
cₓ² − c_y²——对一切圆心与半径成立。 -/
theorem mean_value_x2y2 (cx cy ρ : ℝ) :
    (1 / (2 * π)) * ∫ θ in (0 : ℝ)..2 * π,
      ((cx + ρ * cos θ)^2 - (cy + ρ * sin θ)^2) = cx^2 - cy^2 := by
  -- 倍角恒等式：cos²θ − sin²θ = cos(θ+θ)
  have hcs : ∀ θ : ℝ, cos θ ^ 2 - sin θ ^ 2 = cos (2 * θ) := by
    intro θ
    have e2 : (2 : ℝ) * θ = θ + θ := by ring
    rw [e2, Real.cos_add]
    ring
  -- 被积函数逐项展开（cos²、sin² 作为原子一致出现在两侧）
  have key : ∀ θ : ℝ,
      ((cx + ρ * cos θ)^2 - (cy + ρ * sin θ)^2)
        = (cx^2 - cy^2) + 2 * cx * ρ * cos θ - 2 * cy * ρ * sin θ
            + ρ^2 * cos (2 * θ) := by
    intro θ
    have h1 : (cx + ρ * cos θ)^2 = cx^2 + 2 * cx * ρ * cos θ + ρ^2 * cos θ^2 := by ring
    have h2 : (cy + ρ * sin θ)^2 = cy^2 + 2 * cy * ρ * sin θ + ρ^2 * sin θ^2 := by ring
    rw [h1, h2, ← hcs θ]
    ring
  -- 分项积分（一级 HasDerivAt.add 可 unify；每项单独 FTC）
  -- P = 常数段 + cos 段：∫ P = (cₓ²−c_y²)·2π
  have I1 : ∫ θ in (0 : ℝ)..2 * π, (cx^2 - cy^2) + 2 * cx * ρ * cos θ
      = (cx^2 - cy^2) * (2 * π) := by
    have h : ∀ θ : ℝ,
        HasDerivAt (fun θ => (cx^2 - cy^2) * θ + 2 * cx * ρ * sin θ)
          ((cx^2 - cy^2) * 1 + 2 * cx * ρ * cos θ) θ := fun θ =>
      ((hasDerivAt_id θ).const_mul (cx^2 - cy^2)).add ((hasDerivAt_sin θ).const_mul (2 * cx * ρ))
    rw [integral_congr (f := fun θ => (cx^2 - cy^2) + 2 * cx * ρ * cos θ)
        (g := fun θ => (cx^2 - cy^2) * 1 + 2 * cx * ρ * cos θ) (fun θ _ => by ring),
      integral_eq_sub_of_hasDerivAt (fun θ _ => h θ)]
    · simp only [Real.sin_two_pi, sin_zero, mul_zero, zero_add, sub_zero]
      ring
    · exact (by continuity : Continuous (fun θ : ℝ => (cx^2 - cy^2) * 1 + 2 * cx * ρ * cos θ)).intervalIntegrable 0 (2 * π)
  -- S = sin 段：∫ S = 0
  have Isin : ∫ θ in (0 : ℝ)..2 * π, 2 * cy * ρ * sin θ = 0 := by
    have h : ∀ θ : ℝ,
        HasDerivAt (-fun y => 2 * cy * ρ * cos y) (-(2 * cy * ρ * -sin θ)) θ :=
      fun θ => ((hasDerivAt_cos θ).const_mul (2 * cy * ρ)).neg
    rw [integral_congr (f := fun θ => 2 * cy * ρ * sin θ)
        (g := fun θ => -(2 * cy * ρ * -sin θ)) (fun θ _ => by ring),
      integral_eq_sub_of_hasDerivAt (fun θ _ => h θ)]
    · simp [Real.cos_two_pi, cos_zero]
    · exact (by continuity : Continuous (fun θ : ℝ => -(2 * cy * ρ * -sin θ))).intervalIntegrable 0 (2 * π)
  -- Q = cos2θ 段：∫ Q = 0
  have Icos2 : ∫ θ in (0 : ℝ)..2 * π, ρ^2 * cos (2 * θ) = 0 := by
    have h : ∀ θ : ℝ,
        HasDerivAt (fun θ => ρ^2 * (sin (2 * θ) / 2)) (ρ^2 * (cos (2 * θ) * (2 * 1) / 2)) θ :=
      fun θ => (((hasDerivAt_sin (2 * θ)).comp θ ((hasDerivAt_id θ).const_mul 2)).div_const (2 : ℝ)).const_mul (ρ^2)
    rw [integral_congr (f := fun θ => ρ^2 * cos (2 * θ))
        (g := fun θ => ρ^2 * (cos (2 * θ) * (2 * 1) / 2)) (fun θ _ => by ring),
      integral_eq_sub_of_hasDerivAt (fun θ _ => h θ)]
    · rw [sin_four_pi]
      simp
    · exact (by continuity : Continuous (fun θ : ℝ => ρ^2 * (cos (2 * θ) * (2 * 1) / 2))).intervalIntegrable 0 (2 * π)
  -- 主分项：∫ ((P − S) + Q) = ∫P − ∫S + ∫Q
  rw [integral_congr (fun θ _ => key θ)]
  rw [integral_add ((by continuity : Continuous (fun θ : ℝ => (cx^2 - cy^2) + 2 * cx * ρ * cos θ - 2 * cy * ρ * sin θ)).intervalIntegrable 0 (2 * π))
    ((by continuity : Continuous (fun θ : ℝ => ρ^2 * cos (2 * θ))).intervalIntegrable 0 (2 * π)),
    integral_sub ((by continuity : Continuous (fun θ : ℝ => (cx^2 - cy^2) + 2 * cx * ρ * cos θ)).intervalIntegrable 0 (2 * π))
    ((by continuity : Continuous (fun θ : ℝ => 2 * cy * ρ * sin θ)).intervalIntegrable 0 (2 * π))]
  rw [I1, Isin, Icos2]
  have hp : (2 : ℝ) * π ≠ 0 := by positivity
  field_simp
  ring

end Evanspde.Ch03
