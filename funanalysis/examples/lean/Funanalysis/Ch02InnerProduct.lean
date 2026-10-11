import Mathlib.Analysis.InnerProductSpace.Basic
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.InnerProductSpace.l2Space

/-!
# 第 02 章 · 内积空间初步（Conway I.1）

对应 `docs/02-inner-product.md`。本章在机器中复现 Conway §I.1 的主线：

1. **约定差异**：mathlib 的 `inner 𝕜` 对第一变元共轭线性、第二变元线性；
   Conway 的 `<x, y>` 对第一变元线性。实数域上两者一致，本章取 `𝕜 = ℝ`。
2. **CBS 不等式**：按 Conway 1.4 的"二次三项式判别式"路线手工证明。
3. **极化恒等式与三角不等式**（Conway 1.5 及其前的注记）。
4. **Hilbert 空间的例子**（Conway 1.2/1.3/1.6/1.7）：机器实例。
5. **半内积**（Conway 1.1 的 semi-inner product）：mathlib 的
   `PreInnerProductSpace.Core` 正是它。
-/

open scoped RealInnerProductSpace InnerProductSpace

variable {F : Type*} [NormedAddCommGroup F] [InnerProductSpace ℝ F]

/-!
## 1. 极化恒等式（polar identity）

双线性展开：`‖x + y‖² = ‖x‖² + 2⟪x, y⟫ + ‖y‖²`。
Conway 在 1.5 之前以它为一切后续计算的起点。
-/

theorem fa_polar (x y : F) : ‖x + y‖ ^ 2 = ‖x‖ ^ 2 + 2 * ⟪x, y⟫_ℝ + ‖y‖ ^ 2 := by
  have h : ⟪x + y, x + y⟫_ℝ = ⟪x, x⟫_ℝ + ⟪x, y⟫_ℝ + ⟪y, x⟫_ℝ + ⟪y, y⟫_ℝ :=
    inner_add_add_self x y
  rw [← real_inner_self_eq_norm_sq (x + y), h, ← real_inner_self_eq_norm_sq,
    ← real_inner_self_eq_norm_sq, real_inner_comm y x]
  ring

/-!
## 2. CBS 不等式：Conway 1.4 的判别式证明

对任意实数 t，`⟪x - t • y, x - t • y⟫ ≥ 0`，展开得二次三项式
`q(t) = ‖y‖²·t² - 2⟪x, y⟫·t + ‖x‖² ≥ 0`。抛物线开口向上且处处非负，
故在顶点 `t₀ = ⟪x, y⟫ / ‖y‖²` 处取值非负，即得
`‖x‖²·‖y‖² ≥ ⟪x, y⟫²`。这就是"判别式非正"的代数化身。
-/

theorem fa_cbs_real (x y : F) : ⟪x, y⟫_ℝ ^ 2 ≤ ‖x‖ ^ 2 * ‖y‖ ^ 2 := by
  -- 二次三项式展开
  have expand : ∀ t : ℝ,
      ⟪x - t • y, x - t • y⟫_ℝ = ‖y‖ ^ 2 * t ^ 2 - 2 * ⟪x, y⟫_ℝ * t + ‖x‖ ^ 2 := by
    intro t
    simp only [inner_sub_left, inner_sub_right, real_inner_smul_left,
      real_inner_smul_right, real_inner_comm y x, ← real_inner_self_eq_norm_sq]
    ring
  by_cases hy : y = 0
  · -- y = 0 时两边都是 0
    subst hy
    simp
  · -- y ≠ 0 时 ‖y‖² > 0，取顶点 t₀ 并记录纯乘法关系 ‖y‖²·t₀ = ⟪x,y⟫
    have hpos : 0 < ‖y‖ ^ 2 := by
      have h1 : ⟪y, y⟫_ℝ ≠ 0 := fun h => hy (inner_self_eq_zero.mp h)
      rw [real_inner_self_eq_norm_sq] at h1
      exact lt_of_le_of_ne (by positivity) (Ne.symm h1)
    obtain ⟨t₀, ht₀⟩ : ∃ t₀ : ℝ, ‖y‖ ^ 2 * t₀ = ⟪x, y⟫_ℝ :=
      ⟨⟪x, y⟫_ℝ / ‖y‖ ^ 2, by field_simp⟩
    -- 顶点处取值非负（半正定性）
    have hge : 0 ≤ ⟪x - t₀ • y, x - t₀ • y⟫_ℝ := inner_self_nonneg (𝕜 := ℝ)
    rw [expand t₀] at hge
    -- 两边乘 ‖y‖²，用 ht₀ 消去 t₀：差恰为 (‖y‖²t₀ - ⟪x,y⟫)² 的线性组合
    have hmul : ‖y‖ ^ 2 * (‖y‖ ^ 2 * t₀ ^ 2 - 2 * ⟪x, y⟫_ℝ * t₀ + ‖x‖ ^ 2)
        = ‖x‖ ^ 2 * ‖y‖ ^ 2 - (⟪x, y⟫_ℝ) ^ 2 := by
      linear_combination (‖y‖ ^ 2 * t₀ - ⟪x, y⟫_ℝ) * ht₀
    have h3 : 0 ≤ ‖y‖ ^ 2 * (‖y‖ ^ 2 * t₀ ^ 2 - 2 * ⟪x, y⟫_ℝ * t₀ + ‖x‖ ^ 2) :=
      mul_nonneg (le_of_lt hpos) hge
    rw [hmul] at h3
    linarith

/-!
mathlib 的一般形式（复系数、RCLike）可以直接引用对比：
`inner_mul_inner_self_le : ‖⟪x, y⟫‖ * ‖⟪y, x⟫‖ ≤ re ⟪x, x⟫ * re ⟪y, y⟫`。
-/

example (x y : F) : ⟪x, y⟫_ℝ * ⟪x, y⟫_ℝ ≤ ⟪x, x⟫_ℝ * ⟪y, y⟫_ℝ :=
  real_inner_mul_inner_self_le x y

/-!
## 3. 三角不等式（Conway 1.5 (a)）

先平方，用 CBS 压掉交叉项，再开根号。
-/

theorem fa_triangle (x y : F) : ‖x + y‖ ≤ ‖x‖ + ‖y‖ := by
  -- CBS 的无绝对值形式：⟪x, y⟫ ≤ ‖x‖·‖y‖
  have habs : ⟪x, y⟫_ℝ ≤ ‖x‖ * ‖y‖ := by
    have h2 : ⟪x, y⟫_ℝ ^ 2 ≤ (‖x‖ * ‖y‖) ^ 2 := by
      have h := real_inner_mul_inner_self_le x y
      rw [real_inner_self_eq_norm_sq, real_inner_self_eq_norm_sq] at h
      nlinarith [h]
    exact le_of_sq_le_sq h2 (by positivity)
  have h1 : ‖x + y‖ ^ 2 = ‖x‖ ^ 2 + 2 * ⟪x, y⟫_ℝ + ‖y‖ ^ 2 := fa_polar x y
  have h3 : ‖x + y‖ ^ 2 ≤ (‖x‖ + ‖y‖) ^ 2 := by
    have h4 : 2 * ⟪x, y⟫_ℝ ≤ 2 * (‖x‖ * ‖y‖) := by linarith
    nlinarith [h4]
  calc ‖x + y‖ = Real.sqrt (‖x + y‖ ^ 2) := by rw [Real.sqrt_sq (norm_nonneg _)]
    _ ≤ Real.sqrt ((‖x‖ + ‖y‖) ^ 2) := Real.sqrt_le_sqrt h3
    _ = ‖x‖ + ‖y‖ := Real.sqrt_sq (by positivity)

/-!
## 4. Hilbert 空间的例子（Conway 1.6、1.7）

机器对"完备内积空间"的确认只需一次实例搜索。
ℓ²(I) 在 mathlib 中是 `lp (fun _ : I => 𝕜) 2`。
-/

-- 有限维欧氏空间完备（Conway 1.6：𝔽^d 是 Hilbert 空间）
example {n : ℕ} : CompleteSpace (EuclideanSpace ℝ (Fin n)) := by infer_instance

-- ℓ²(ℕ)：平方可和复数列，Conway 1.7 的机器化身
example : CompleteSpace (lp (fun _ : ℕ => ℂ) 2) := by infer_instance

-- 任意指标集上的 ℓ²(I) 也是 Hilbert 空间
example {I : Type*} : CompleteSpace (lp (fun _ : I => ℂ) 2) := by infer_instance

/-!
## 5. 半内积（Conway 1.1 定义的 semi-inner product）

mathlib 的 `PreInnerProductSpace.Core` 正是 Conway 的半内积：
只需埃尔米特对称、半正定、对第一变元共轭线性。
"半"字体现在：不要求 `⟪x, x⟫ = 0 → x = 0`。
打印它的字段做对照：
-/

#print PreInnerProductSpace.Core
