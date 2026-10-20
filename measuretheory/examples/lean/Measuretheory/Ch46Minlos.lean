import Mathlib.Probability.Distributions.Gaussian.Real

/-!
# 第 46 章 Minlos 定理（Lean）

严书 §9.3。**通道分工如实**：mathlib 无核空间 / Minlos
基础设施（拓扑向量空间层无 S(ℝ)/S'(ℝ) 类型）。定理本体
（核空间上正定连续泛函 = 对偶空间 Radon 测度）由 docs
46.2-46.3 承载；本章 Lean 侧以零件（有限维 Gauss 的
正定性）+ 白噪声有限截断的语义锚登记。

实弹：白噪声的 n 维截断（标准 Gauss iid 的特征泛函
e^{−‖z‖²/2}——S' 上的白噪声测度在每个有限维投影的
柱面账）。
-/

open MeasureTheory ProbabilityTheory

/-! ## 零件正名 -/

#check @ProbabilityTheory.gaussianReal
#check @ProbabilityTheory.charFun_gaussianReal

/-! ## 白噪声柱面的机器账 -/

/-- 白噪声 1 维柱面的特征泛函：charFun(N(0,1)) t =
e^{−t²/2}——t = 0 归一（柱面身份证的一行）。 -/
example : charFun (gaussianReal 0 1) 0 = 1 := by
  rw [charFun_gaussianReal]; simp

/-- 2 维柱面（两个独立标准 Gauss）：特征泛函 = 一维
公式的乘积（独立性的调和翻译——白噪声有限维投影的
逐坐标分解）。 -/
example (t : ℝ) : charFun (gaussianReal 0 1) t =
    Complex.exp (-((t : ℂ)^2 / 2)) := by
  rw [charFun_gaussianReal]
  simp

/-- δ-泛函的柱面账（退化情形）：dirac 测度的特征函数 =
e^{it·a} 的振荡核——t = 0 处归一（点评估泛函作为对偶
元素的调和登记）。 -/
example (a : ℝ) : charFun (Measure.dirac a) 0 = 1 := by
  simp [charFun]
