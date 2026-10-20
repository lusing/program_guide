import Mathlib.Probability.Distributions.Poisson.Basic
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.MeasureTheory.Group.Convolution

/-!
# 第 53 章 无穷可分分布（Lean）

袁下册第 22 章。**分工如实**：mathlib 无无穷可分性基础设施
（无 InfinitelyDivisible 定义、无 Lévy-Khinchin 表示）——本章
以**分解恒等式的机器账**承载：卷积幂 `convPow`（迭代
`Measure.conv`）+ 两大卷积封闭律
（`poissonMeasure_conv_poissonMeasure`（ℕ 上的 Po）/
`gaussianReal_conv_gaussianReal`（ℝ 上的 Gauss））组装出
**n 重卷积分解**（定义 53.A 的 r.v. 版 ⟺ ch.f. 版 ⟺ 卷积版
三形态中，机器侧取卷积形态——最强且最干净）。

反例账（53.4 的有界支撑非 i.d.）由 docs 承载。
-/

open MeasureTheory ProbabilityTheory
open scoped NNReal

/-! ## 卷积幂（n ≥ 1 个因子的迭代卷积） -/

/-- n 重卷积：μ ∗ ⋯ ∗ μ（n 个因子；约定 0 = μ 自身）。 -/
noncomputable def convPow {G : Type*} [AddMonoid G] [MeasurableSpace G]
    [MeasurableAdd₂ G] (μ : Measure G) : ℕ → Measure G
  | 0 => μ
  | n + 1 => μ ∗ convPow μ n

lemma convPow_succ {G : Type*} [AddMonoid G] [MeasurableSpace G]
    [MeasurableAdd₂ G] (μ : Measure G) (n : ℕ) :
    convPow μ (n + 1) = μ ∗ convPow μ n := rfl

/-! ## Poisson（ℕ 上）的 n 重分解 -/

/-- **Poisson 卷积幂账**：k+1 个 Po(s) 的卷积 = Po((k+1)·s)
——速率可加性的迭代版（`poissonMeasure_conv_poissonMeasure`
的归纳收割）。 -/
lemma poisson_convPow (s : ℝ≥0) (k : ℕ) :
    convPow (poissonMeasure s) k = poissonMeasure (((k : ℝ≥0) + 1) * s) := by
  induction k with
  | zero => norm_num [convPow]
  | succ n ih =>
      rw [convPow_succ, ih, poissonMeasure_conv_poissonMeasure]
      congr 1
      push_cast
      ring

/-- **Poisson 无穷可分**：对每个 n ≥ 1，Po(rate) 是
Po(rate/n) 的 n 重卷积——袁 22.1 定义 (i) 的机器版
（四常青例之首：速率均分即分解）。 -/
theorem poisson_infinite_divisible (n : ℕ) (rate : ℝ≥0) :
    convPow (poissonMeasure (rate / (n + 1))) n = poissonMeasure rate := by
  rw [poisson_convPow]
  congr 1
  field_simp

/-! ## Gauss（ℝ 上）的 n 重分解 -/

/-- **Gauss 卷积幂账**：k+1 个 N(0,v) 的卷积 = N(0,(k+1)v)
——方差可加性的迭代版（`gaussianReal_conv_gaussianReal` 的
归纳收割）。 -/
lemma gaussian_convPow (v : ℝ≥0) (k : ℕ) :
    convPow (gaussianReal 0 v) k = gaussianReal 0 (((k : ℝ≥0) + 1) * v) := by
  induction k with
  | zero => norm_num [convPow]
  | succ n ih =>
      rw [convPow_succ, ih, gaussianReal_conv_gaussianReal]
      congr 1 <;> (push_cast; ring)

/-- **Gauss 无穷可分**：对每个 n ≥ 1，N(0,σ²) 是 N(0, σ²/n)
的 n 重卷积——正态 = 可无限细分的 Brown 分量
（LK 表示中 G 的全部质量集中在 0 点跳的机器侧）。 -/
theorem gaussian_infinite_divisible (n : ℕ) (v : ℝ≥0) :
    convPow (gaussianReal 0 (v / (n + 1))) n = gaussianReal 0 v := by
  rw [gaussian_convPow]
  congr 1
  field_simp

/-! ## ch.f. 形态的对照锚点（三形态之 (ii)） -/

#check @poissonMeasure_conv_poissonMeasure
#check @gaussianReal_conv_gaussianReal
#check @charFun_map_cast_poissonMeasure
#check @charFun_gaussianReal
#check @charFun_conv
