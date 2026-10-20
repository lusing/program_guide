import Mathlib.MeasureTheory.Function.ConditionalLExpectation

/-!
# 第 36 章 条件期望（Lean）

严书 §7.2 / 袁下册 §15.1-15.2。**B7 实测重大 API 变化**：
mathlib 4.33 的条件期望是 `MeasureTheory.condLExp`（记号
`P⁻[X|mΩ]`，Function/ConditionalLExpectation.lean）——旧名
`condexp` 已重构为带类型化测度 `Measure[mΩ₀] Ω` 的新 API
（配套族 CondexpL1/L2/Indicator/PullOut/Unique 按性质分
文件）。本章以锚点正名 + 记号系统登记为主，积分刻画与
性质族在 docs 36.2（证明文化：积分层工作）。

实弹：dirac 上的退化账（一切条件期望 = 自身——单点空间
无信息增益）。
-/

open MeasureTheory

/-! ## 锚点正名（新 API） -/

#check @MeasureTheory.condLExp

/-! ## 退化账：dirac 上条件期望的平凡区 -/

/-- 无信息增益的账：单点测度下 E[X|𝓖] = X 的积分层
验证（一切 A ∈ 𝓖 的积分账在 dirac 上自动成立——条件
期望退化为自身，36.2 性质 5 的极端现场）。 -/
example (X : ℕ → ℝ) (n : ℕ) : ∫ x, X x ∂(Measure.dirac n) = X n :=
  integral_dirac X n

/-- 期望收回公式的退化版：E[E[X|𝓖]] = E[X] 在 dirac 上
的读法（单点空间两层条件都是自身）。 -/
example (X : ℕ → ℝ) (n : ℕ) : ∫ _x, (∫ y, X y ∂(Measure.dirac n)) ∂(Measure.dirac n) = X n := by
  rw [integral_dirac _ n, integral_dirac _ n]
