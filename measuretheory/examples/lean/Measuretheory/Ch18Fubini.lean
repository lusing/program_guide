import Mathlib.MeasureTheory.Integral.Prod

/-!
# 第 18 章 乘积测度与 Fubini 定理（Lean）

严书 §4.2 / 袁上册 §10.2-10.3。mathlib 锚点：`Measure.prod`
（σ-有限乘积测度）、矩形账 `Measure.prod_prod`（μ×ν(s×ˢt) =
μs·νt，Prod.lean:231）、Tonelli = `lintegral_prod` / 对称版
`lintegral_prod_swap`、Fubini = `integral_prod` / `integral_prod_
symm`（Integral/Prod.lean:444-467）。

实弹：dirac 对的乘积折叠（`dirac_prod_dirac`）、Tonelli 的
逐片记账在 dirac 上的完全坍缩、单位方块上体积账 1·1 = 1。
-/

open MeasureTheory
open scoped ENNReal

/-! ## 锚点正名 -/

#check @Measure.prod
#check @Measure.prod_prod
#check @lintegral_prod
#check @lintegral_prod_swap
#check @integral_prod
#check @integral_prod_symm
#check @Measure.dirac_prod_dirac
#check @Measure.prod_swap

/-! ## 矩形账 -/

/-- dirac × dirac 折叠成单点 dirac：乘积测度在"完全集中"情形
的显式坍缩。 -/
example (x y : ℝ) : (Measure.dirac x).prod (Measure.dirac y) = Measure.dirac (x, y) :=
  Measure.dirac_prod_dirac

/-- 矩形账 μ×ν(s ×ˢ t) = μ s · ν t 的 dirac 实弹：对角点账 = 1·1。
`Measure.prod_prod` 无需集合可测（对一切集合成立）。 -/
example (a : ℝ) : (Measure.dirac a).prod (Measure.dirac a) ({a} ×ˢ {a}) = 1 := by
  rw [Measure.prod_prod]
  simp

/-- 单位方块上的体积账：restrict × restrict 的矩形账 = 1·1 = 1
——Lebesgue 情形的矩形记账（18.1 的 (a) 步在具体数上落账）。 -/
example : (Measure.restrict (volume : Measure ℝ) (Set.Ioc (0:ℝ) 1)).prod
    (Measure.restrict (volume : Measure ℝ) (Set.Ioc (0:ℝ) 1))
    (Set.Ioc (0:ℝ) 1 ×ˢ Set.Ioc (0:ℝ) 1) = 1 := by
  rw [Measure.prod_prod]
  simp [Measure.restrict_apply, Set.inter_self, Real.volume_Ioc]

/-! ## Tonelli：逐片记账的坍缩 -/

/-- Tonelli 在 dirac 上坍缩成"取值"：∫⁻ f d(δ₀×δ₁) = f(0,1)。
两步 `lintegral_dirac` 正是"先 y 后 x"的逐片记账。 -/
example (f : ℝ × ℝ → ℝ≥0∞)
    (hf : AEMeasurable f ((Measure.dirac 0).prod (Measure.dirac 1))) :
    ∫⁻ z, f z ∂((Measure.dirac 0).prod (Measure.dirac 1)) = f (0, 1) := by
  rw [lintegral_prod _ hf, lintegral_dirac, lintegral_dirac]

/-- 对称片：`lintegral_prod_swap`——把 (ν×μ) 上看 f∘swap 的账
搬回 (μ×ν) 上的原账（measurePreserving 换序）。与上例合读：
非负执照下"先 x 后 y"与"先 y 后 x"给出同一笔账。 -/
example (f : ℝ × ℝ → ℝ≥0∞) :
    ∫⁻ z, f z.swap ∂((Measure.dirac 1).prod (Measure.dirac 0))
      = ∫⁻ z, f z ∂((Measure.dirac 0).prod (Measure.dirac 1)) :=
  lintegral_prod_swap f
