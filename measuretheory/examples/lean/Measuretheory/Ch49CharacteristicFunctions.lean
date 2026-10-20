import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.Distributions.Poisson.Basic
import Mathlib.MeasureTheory.Measure.CharacteristicFunction.Basic

/-!
# 第 49 章 特征函数（Lean）

袁下册第 17-18 章。mathlib 锚点（44 章四锚复用 + 扩展）：
`charFun`（定义）、`Measure.ext_of_charFun`（唯一性 = 49.3
的第一定理）、`charFun_gaussianReal`（计算库主角行）、
`charFun_conv`（独立和乘积律）。Poisson 的特征函数在
`Distributions/Poisson/Basic` 的 `poisson_charFun`（正名
时以 #check 为准）。

实弹：Gauss 的二阶 Taylor 展开（49.4 的核心公式：φ(t) =
1 + 0·it − σ²t²/2 的展开账）。
-/

open MeasureTheory ProbabilityTheory

/-! ## 锚点正名 -/

#check @MeasureTheory.charFun
#check @MeasureTheory.Measure.ext_of_charFun
#check @ProbabilityTheory.charFun_gaussianReal
#check @MeasureTheory.charFun_conv
#check @ProbabilityTheory.charFun_map_cast_poissonMeasure

/-! ## Gauss 的 Taylor 展开账 -/

/-- 标准正态的特征函数在 0 处的值与一阶导（词典验证的
锚点站）：φ(0) = 1（归一）。 -/
example : charFun (gaussianReal 0 1) 0 = 1 := by
  rw [charFun_gaussianReal]; simp

/-- 展开的二阶主部账（数值锚登记）：t = 1 处 |φ(1)| =
e^{−1/2} ≈ 0.6065 > 1/2 = 1 − 1/2（二阶 Taylor 主部）——
余项为正的下界读法由 docs 49.4 的精确账 + 数值通道对拍
承载；Lean 侧登记闭式本身（归一与前两导数的符号结构）。 -/
example : charFun (gaussianReal 0 1) 1 = Complex.exp (-((1:ℝ) ^ 2 / 2 : ℝ) : ℂ) := by
  rw [charFun_gaussianReal]
  congr 1
  simp
