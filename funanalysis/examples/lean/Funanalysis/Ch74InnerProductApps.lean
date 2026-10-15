import Mathlib.Analysis.InnerProductSpace.Basic
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Order.Filter.AtTopBot.Defs
import Mathlib.MeasureTheory.Function.L2Space
import Mathlib.Analysis.Normed.Lp.lpSpace

/-!
# 第 74 章 · 内积的应用：相关系数、Gram 矩阵与最佳逼近（工科篇 4.4-4.5）

书 4.5 节把 Hilbert 空间理论落到工程计算：信号相似性（最小二乘
尺度拟合 → 规范相关系数）、最佳逼近的法方程、Gram 矩阵的可逆性
判据与行列式距离公式；4.4.5 给出弱收敛的内外积刻画。

本章 Lean 通道：
1. **最小二乘配平方全证**：‖x − λy‖² = ‖y‖²(λ − λ*)² + 常数，
   λ* = ⟨x,y⟩/‖y‖²——相关系数 |ρ| ≤ 1 与最优相对误差 1 − ρ² 的
   一次性来源；
2. **弱收敛恒等式**（书 4.4.5）：‖xₙ − x‖² = ‖xₙ‖² − 2⟨xₙ,x⟩ + ‖x‖²，
   及"弱收敛 + 范数收敛 ⟹ 强收敛"。
-/

open RealInnerProductSpace InnerProductSpace Filter
open scoped Topology
open scoped RealInnerProductSpace InnerProductSpace

variable {H : Type*} [NormedAddCommGroup H] [InnerProductSpace ℝ H]

/-! ## 第一层：最小二乘尺度拟合与相关系数 -/

/-- **配平方恒等式（最小二乘尺度拟合）**：对任意尺度 λ，
‖x − λy‖² 恰是"最优尺度 λ* = ⟨x,y⟩/‖y‖² 的偏离平方 + 不可约误差"。
书 4.5.1 的核心计算——dQ/dλ = 0 解出 λ* 后的能量展开。 -/
theorem least_squares_square (x y : H) (hy : y ≠ 0) (lam : ℝ) :
    ‖x - lam • y‖ ^ 2
      = ‖y‖ ^ 2 * (lam - ⟪x, y⟫_ℝ / ‖y‖ ^ 2) ^ 2
        + (‖x‖ ^ 2 - ⟪x, y⟫_ℝ ^ 2 / ‖y‖ ^ 2) := by
  have hexp : ‖x - lam • y‖ ^ 2
      = ‖x‖ ^ 2 - 2 * lam * ⟪x, y⟫_ℝ + lam ^ 2 * ‖y‖ ^ 2 := by
    rw [norm_sub_sq_real, real_inner_smul_right, norm_smul]
    simp only [mul_pow, Real.norm_eq_abs, sq_abs]
    ring
  have hne : ‖y‖ ^ 2 ≠ 0 := by positivity
  rw [hexp]
  field_simp
  ring

/-- **推论：最优尺度使误差取最小**——偏离最优尺度的代价是一枚
非负平方（书 4.5.1：min Q 在 λ = Σxᵢyᵢ/Σyᵢ² 处取得）。 -/
theorem least_squares_min (x y : H) (hy : y ≠ 0) :
    ‖x‖ ^ 2 - ⟪x, y⟫_ℝ ^ 2 / ‖y‖ ^ 2 ≤ ‖x - (⟪x, y⟫_ℝ / ‖y‖ ^ 2) • y‖ ^ 2 := by
  rw [least_squares_square x y hy]
  simp

/-- **规范相关系数与 Schwarz 不等式**（书 4.5.1）：|ρ| ≤ 1，且
最优相对能量误差恰为 1 − ρ²（ρ = ±1 ⟹ 完全相似）。 -/
example (x y : H) : |⟪x, y⟫_ℝ| ≤ ‖x‖ * ‖y‖ := by
  exact abs_real_inner_le_norm x y

/-! ## 第二层：弱收敛恒等式（书 4.4.5） -/

/-- **范数展开恒等式**：‖xₙ − x‖² = ‖xₙ‖² − 2⟨xₙ,x⟩ + ‖x‖²
——弱收敛 + 范数收敛 ⟹ 强收敛的全部机制。 -/
theorem norm_sq_expand (xn x : H) :
    ‖xn - x‖ ^ 2 = ‖xn‖ ^ 2 - 2 * ⟪xn, x⟫_ℝ + ‖x‖ ^ 2 := by
  have h : ‖xn - x‖ ^ 2 = ⟪xn - x, xn - x⟫_ℝ :=
    (real_inner_self_eq_norm_sq _).symm
  rw [h]
  simp only [inner_sub_left, inner_sub_right, real_inner_comm,
    real_inner_self_eq_norm_sq]
  ring

/-- **弱收敛 + 范数收敛 ⟹ 强收敛**（书 4.4.5(2) 的充分性）：
内积逐点对齐 + 范数对齐 ⟹ 距离归零。 -/
theorem weak_plus_norm_implies_strong (seq : ℕ → H) (x : H)
    (hinner : ∀ y, Tendsto (fun n => ⟪seq n, y⟫_ℝ) atTop (𝓝 ⟪x, y⟫_ℝ))
    (hnorm : Tendsto (fun n => ‖seq n‖) atTop (𝓝 ‖x‖)) :
    Tendsto (fun n => ‖seq n - x‖) atTop (𝓝 0) := by
  have h1 : Tendsto (fun n : ℕ => ‖seq n‖ ^ 2 - 2 * ⟪seq n, x⟫_ℝ + ‖x‖ ^ 2)
      atTop (𝓝 (‖x‖ ^ 2 - 2 * ⟪x, x⟫_ℝ + ‖x‖ ^ 2)) :=
    Tendsto.add (Tendsto.sub (hnorm.pow 2) (Tendsto.const_mul 2 (hinner x)))
      tendsto_const_nhds
  have h2 : ‖x‖ ^ 2 - 2 * ⟪x, x⟫_ℝ + ‖x‖ ^ 2 = 0 := by
    rw [real_inner_self_eq_norm_sq]
    ring
  rw [h2] at h1
  have hsq : Tendsto (fun n => ‖seq n - x‖ ^ 2) atTop (𝓝 0) :=
    h1.congr (fun n => (norm_sq_expand (seq n) x).symm)
  have hsqt : Tendsto (fun n => Real.sqrt (‖seq n - x‖ ^ 2)) atTop (𝓝 (Real.sqrt 0)) :=
    (continuous_id.sqrt.tendsto 0).comp hsq
  have hsimp : ∀ n, Real.sqrt (‖seq n - x‖ ^ 2) = ‖seq n - x‖ := fun n =>
    Real.sqrt_sq (norm_nonneg _)
  simpa [hsimp] using hsqt

/-! ## 第三层：Gram 矩阵锚点 -/

-- Gram 矩阵 = 有限向量族的半双线性型矩阵；可逆 ⟺ 线性无关（书 4.5.5）
-- 其正定性（⟪G a, a⟫ = ‖Σaᵢxᵢ‖² ≥ 0）正是 Schwarz 不等式的化身：
#check @abs_real_inner_le_norm

-- L² 空间上的积分内积 ⟨f,g⟩ = ∫fg（书 4.5 习题 1 的机器对应）
#check @MeasureTheory.L2.innerProductSpace
