import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.MeasureTheory.Measure.CharacteristicFunction.Basic

/-!
# 第 44 章 Bochner 定理（Lean）

严书 §9.1 / 袁下册 17.4。mathlib 锚点（Measure/
CharacteristicFunction/Basic.lean）：`charFun`（特征函数
的 InnerProductSpace 版——`∫ x, exp (⟪x, t⟫ * I) ∂μ`）、
**唯一性定理 `Measure.ext_of_charFun`**（完全指纹——
Bochner 定理的"唯一性半边"机器版）、`charFun_gaussianReal`
（高斯的特征函数闭式 e^{itμ − σ²t²/2}——正定判例库首行
的机器版）与 `charFun_conv`（卷积乘积律）。

实弹：高斯特征函数的显式收割。
-/

open MeasureTheory ProbabilityTheory

/-! ## 锚点正名 -/

#check @MeasureTheory.charFun
#check @MeasureTheory.Measure.ext_of_charFun
#check @ProbabilityTheory.charFun_gaussianReal
#check @MeasureTheory.charFun_conv

/-! ## 高斯特征函数的显式收割 -/

/-- 标准 Gauss 的特征函数：charFun(gaussianReal 0 1) t =
e^{−t²/2}——正定判例库首行的机器版（t = 0 处 φ(0) = 1
的归一核对）。 -/
example : charFun (gaussianReal 0 1) 0 = 1 := by
  rw [charFun_gaussianReal]
  simp

/-- 位置参数 μ 的平移账：charFun(N(μ,1)) t = e^{itμ−t²/2}——
t = 0 仍归一（位置不改变总质量）。 -/
example (mu : ℝ) : charFun (gaussianReal mu 1) 0 = 1 := by
  rw [charFun_gaussianReal]
  simp

/-- 唯一性的退化实例：两个测度若 charFun 逐点相等则相等
——`ext_of_charFun` 的调用形态登记（前提条件以 mathlib
文件内的完整签名见上方 #check）。 -/
example (μ ν : Measure ℝ) (h : ∀ t, charFun μ t = charFun ν t)
    [IsProbabilityMeasure μ] [IsProbabilityMeasure ν] : μ = ν := by
  exact Measure.ext_of_charFun (E := ℝ) (funext h)
