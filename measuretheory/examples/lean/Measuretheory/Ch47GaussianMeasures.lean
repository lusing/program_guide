import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.BrownianMotion.Basic

/-!
# 第 47 章 Hilbert 空间上的 Gauss 测度（Lean）

严书 §9.4-9.5。mathlib 锚点：`gaussianReal`（一维正态
的完全类型化：Probability/Distributions/Gaussian/Real.
lean:222）、`charFun_gaussianReal`（调和刻画——47.1 定义
形态表第三行的实值版）、BrownianMotion 文件族（本章理论
的最大应用：布朗运动的构造在 mathlib 已形式化——43 章
轨道装修预告的兑现现场）。

实弹：Gauss 的对称账（N(−μ,σ) 与 N(μ,σ) 的镜像——
均值符号翻转）与标准正态的归一账。
-/

open MeasureTheory ProbabilityTheory
open scoped NNReal

/-! ## 锚点正名 -/

#check @ProbabilityTheory.gaussianReal
#check @ProbabilityTheory.charFun_gaussianReal

/-! ## Gauss 的即时账 -/

/-- 归一账：一切概率 Gauss 的特征函数在 0 处 = 1
（总质量归一——一维投影的正态性起点）。 -/
example (mu : ℝ) (v : NNReal) : charFun (gaussianReal mu v) 0 = 1 := by
  rw [charFun_gaussianReal]; simp

/-- 对称 Gauss 的镜像账：N(0,1) 的特征函数是偶函数
（对称分布的调和登记——φ(−t) = φ(t)，正定性的 Hermite
对称在一维的具体化）。 -/
example (t : ℝ) : charFun (gaussianReal 0 1) (-t)
    = charFun (gaussianReal 0 1) t := by
  rw [charFun_gaussianReal, charFun_gaussianReal]
  simp
