import Mathlib.Analysis.InnerProductSpace.Basic
import Mathlib.Analysis.InnerProductSpace.Projection.Basic
import Mathlib.Analysis.InnerProductSpace.Projection.Minimal
import Mathlib.Analysis.InnerProductSpace.Projection.Submodule

/-!
# 第 03 章 · 正交性与投影定理（Conway I.2）

对应 `docs/03-orthogonality.md`。本章在机器中复现 Conway §I.2 的主线：

1. **勾股定理**（Conway 2.2）与**平行四边形恒等式**（Conway 2.3）：
   手工展开一遍，再引用 mathlib 的现成形式对照。
2. **最近点唯一性**（Conway 2.5 的唯一性部分）：完全按书的平行四边形论证。
3. **正交投影**（Conway 2.6-2.8）：mathlib 的 `Submodule` 投影 API。
4. **M⊥⊥ = M**（Conway 2.9）。
-/

open scoped RealInnerProductSpace InnerProductSpace

variable {F : Type*} [NormedAddCommGroup F] [InnerProductSpace ℝ F]

/-!
## 1. 勾股定理（Conway 2.2）

若 ⟪x, y⟫ = 0 则 ‖x + y‖² = ‖x‖² + ‖y‖²。
先手工证明（极化恒等式，与第 02 章同源），再展示 mathlib 现成引理。
-/

-- 极化恒等式（本章自足版本，即第 02 章的 fa_polar）
theorem fa_polar (x y : F) : ‖x + y‖ ^ 2 = ‖x‖ ^ 2 + 2 * ⟪x, y⟫_ℝ + ‖y‖ ^ 2 := by
  have h : ⟪x + y, x + y⟫_ℝ = ⟪x, x⟫_ℝ + ⟪x, y⟫_ℝ + ⟪y, x⟫_ℝ + ⟪y, y⟫_ℝ :=
    inner_add_add_self x y
  rw [← real_inner_self_eq_norm_sq (x + y), h, ← real_inner_self_eq_norm_sq,
    ← real_inner_self_eq_norm_sq, real_inner_comm y x]
  ring

theorem fa_pythagoras_manual {x y : F} (h : ⟪x, y⟫_ℝ = 0) :
    ‖x + y‖ ^ 2 = ‖x‖ ^ 2 + ‖y‖ ^ 2 := by
  have h1 : ‖x + y‖ ^ 2 = ‖x‖ ^ 2 + 2 * ⟪x, y⟫_ℝ + ‖y‖ ^ 2 := fa_polar x y
  rw [h] at h1
  linarith

-- mathlib 的现成形式（复情形一般版；v4.33.1 的陈述用乘积表示平方）
example {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℂ E] {x y : E}
    (h : ⟪x, y⟫_ℂ = 0) : ‖x + y‖ * ‖x + y‖ = ‖x‖ * ‖x‖ + ‖y‖ * ‖y‖ :=
  norm_add_sq_eq_norm_sq_add_norm_sq_of_inner_eq_zero x y h

/-!
## 2. 平行四边形恒等式（Conway 2.3）

`‖x + y‖² + ‖x - y‖² = 2(‖x‖² + ‖y‖²)`：
两条极化恒等式（加、减）相加即得。
-/

theorem fa_polar_sub (x y : F) : ‖x - y‖ ^ 2 = ‖x‖ ^ 2 - 2 * ⟪x, y⟫_ℝ + ‖y‖ ^ 2 := by
  have h : ⟪x - y, x - y⟫_ℝ = ⟪x, x⟫_ℝ - ⟪x, y⟫_ℝ - ⟪y, x⟫_ℝ + ⟪y, y⟫_ℝ :=
    inner_sub_sub_self x y
  rw [← real_inner_self_eq_norm_sq (x - y), h, ← real_inner_self_eq_norm_sq,
    ← real_inner_self_eq_norm_sq, real_inner_comm y x]
  ring

theorem fa_parallelogram_manual (x y : F) :
    ‖x + y‖ ^ 2 + ‖x - y‖ ^ 2 = 2 * (‖x‖ ^ 2 + ‖y‖ ^ 2) := by
  have e1 := fa_polar x y
  have e2 := fa_polar_sub x y
  linarith

-- mathlib 的现成形式（v4.33.1 中 𝕜 是显式参数）
example (x y : F) : ‖x + y‖ ^ 2 + ‖x - y‖ ^ 2 = 2 * (‖x‖ ^ 2 + ‖y‖ ^ 2) :=
  parallelogram_law_with_norm ℝ x y

/-!
## 3. 最近点的唯一性（Conway 2.5 的后半）

设 K 凸，u、v ∈ K 都是到原点最近的点（范数等于下确界 d），
则中点 (u+v)/2 ∈ K，故 ‖(u+v)/2‖ ≥ d，即 ‖u+v‖ ≥ 2d。
代入平行四边形恒等式得 ‖u - v‖² ≤ 2d² + 2d² - 4d² = 0。
-/

theorem fa_minimizer_unique {K : Set F} (hconv : Convex ℝ K) {d : ℝ} {u v : F}
    (huK : u ∈ K) (hvK : v ∈ K)
    (hmin : ∀ w ∈ K, d ≤ ‖w‖) (humin : ‖u‖ = d) (hvmin : ‖v‖ = d) : u = v := by
  -- 中点属于 K（凸性；v4.33.1 的 Convex 是 a,b ≥ 0、a + b = 1 三段式）
  have hm : (2 : ℝ) ⁻¹ • (u + v) ∈ K := by
    have hc : (1 / 2 : ℝ) • u + (1 / 2 : ℝ) • v ∈ K :=
      hconv huK hvK (by norm_num) (by norm_num) (by norm_num)
    have heq : (1 / 2 : ℝ) • u + (1 / 2 : ℝ) • v = (2 : ℝ) ⁻¹ • (u + v) := by
      rw [← smul_add]
      congr 1
      norm_num
    rw [← heq]
    exact hc
  -- 中点范数 ≥ d ⟹ ‖u + v‖ ≥ 2d
  have hnorm : d ≤ ‖(2 : ℝ) ⁻¹ • (u + v)‖ := hmin _ hm
  have hsmul : ‖(2 : ℝ) ⁻¹ • (u + v)‖ = (2 : ℝ) ⁻¹ * ‖u + v‖ := by
    rw [norm_smul]; simp
  have h2 : 2 * d ≤ ‖u + v‖ := by
    rw [hsmul] at hnorm
    nlinarith [hnorm, two_pos (α := ℝ)]
  -- 平行四边形收尾
  have hpara : ‖u + v‖ ^ 2 + ‖u - v‖ ^ 2 = 2 * (‖u‖ ^ 2 + ‖v‖ ^ 2) :=
    fa_parallelogram_manual u v
  -- 把 2d ≤ ‖u+v‖ 平方成 4d² ≤ ‖u+v‖²（d ≥ 0 来自 humin）
  have hd : 0 ≤ d := by rw [← humin]; exact norm_nonneg u
  have h4 : (2 * d) * (2 * d) ≤ (‖u + v‖) * (‖u + v‖) :=
    mul_self_le_mul_self (by linarith) h2
  have hle : ‖u - v‖ ^ 2 ≤ 0 := by nlinarith [h4, hpara, humin, hvmin]
  have hzero : ‖u - v‖ = 0 := by
    have := le_antisymm hle (sq_nonneg _)
    exact pow_eq_zero_iff (two_ne_zero) |>.mp this
  exact sub_eq_zero.mp (norm_eq_zero.mp hzero)

/-!
存在性由 mathlib 的 `exists_norm_eq_iInf_of_complete_convex` 给出
（完备凸集的 Hilbert 投影定理），两者合成即 Conway 2.5 全文。
-/

#check @exists_norm_eq_iInf_of_complete_convex

/-!
## 4. 正交投影（Conway 2.6-2.8）

mathlib 把"闭子空间上的正交投影"做成 `K.starProjection : E →L[𝕜] E`；
关键事实与 Conway 2.6-2.7 一一对应。
-/

section Projection

variable {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E] {K : Submodule ℝ E}

-- Conway 2.6：投影误差与子空间正交
example [K.HasOrthogonalProjection] (v w : E) (hw : w ∈ K) :
    ⟪v - K.starProjection v, w⟫_ℝ = 0 :=
  K.starProjection_inner_eq_zero v w hw

-- Conway 2.6（刻画）：v 到 K 的距离恰在投影处达到 ⟺ 误差正交
example [K.HasOrthogonalProjection] {u v : E} (hv : v ∈ K) :
    (‖u - v‖ = ⨅ w : K, ‖u - w‖) ↔ ∀ w ∈ K, ⟪u - v, w⟫_ℝ = 0 :=
  K.norm_eq_iInf_iff_inner_eq_zero hv

-- Conway 2.7 (c)：投影幂等（用唯一性刻画直接得）
example [K.HasOrthogonalProjection] (v : E) :
    K.starProjection (K.starProjection v) = K.starProjection v :=
  K.eq_starProjection_of_mem_of_inner_eq_zero (K.starProjection_apply_mem v)
    (fun _ _ => by rw [sub_self, inner_zero_left])

/-!
Conway 2.7 (b)：‖Pv‖ ≤ ‖v‖。按书上的路线手工做——
分解 v = Pv + (v - Pv) 是正交分解，勾股定理给出
`‖v‖² = ‖Pv‖² + ‖v - Pv‖² ≥ ‖Pv‖²`。
-/

example [K.HasOrthogonalProjection] (v : E) : ‖K.starProjection v‖ ≤ ‖v‖ := by
  set p := K.starProjection v with hp
  set r := v - K.starProjection v with hr
  have horth : ⟪p, r⟫_ℝ = 0 := by
    have h1 : ⟪v - K.starProjection v, K.starProjection v⟫_ℝ = 0 :=
      K.starProjection_inner_eq_zero v _ (K.starProjection_apply_mem v)
    rw [real_inner_comm]
    exact h1
  have hpy : ‖p‖ * ‖p‖ + ‖r‖ * ‖r‖ = ‖p + r‖ * ‖p + r‖ :=
    (norm_add_sq_eq_norm_sq_add_norm_sq_of_inner_eq_zero p r horth).symm
  have hsum : p + r = v := by
    rw [hp, hr]
    abel
  rw [hsum] at hpy
  have hnn : 0 ≤ ‖r‖ * ‖r‖ := mul_self_nonneg _
  have hle : ‖p‖ * ‖p‖ ≤ ‖v‖ * ‖v‖ := by linarith
  calc ‖p‖ = Real.sqrt (‖p‖ * ‖p‖) := by rw [Real.sqrt_mul_self (norm_nonneg _)]
    _ ≤ Real.sqrt (‖v‖ * ‖v‖) := Real.sqrt_le_sqrt hle
    _ = ‖v‖ := by rw [Real.sqrt_mul_self (norm_nonneg _)]

-- Conway 2.9：M⊥⊥ = M
example [K.HasOrthogonalProjection] : Kᗮᗮ = K := K.orthogonal_orthogonal

end Projection
