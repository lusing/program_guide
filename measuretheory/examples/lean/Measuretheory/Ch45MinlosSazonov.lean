import Mathlib.Probability.Distributions.Gaussian.Real

/-!
# 第 45 章 Minlos-Sazonov 定理（Lean）

严书 §9.2。**通道分工如实**：mathlib 无 Sazonov 拓扑 /
迹型连续性基础设施（CharacteristicFunction/Basic.lean 的
`charFunDual`（StrongDual 版特征函数）是最近的零件——
对偶拓扑侧的类型化）。定理本体（正定 + *-连续 ⟺ 可数
可加）由 docs 45.2 三步骨架承载；数值通道做特征值收费
实验（λₙ = 1/n² 收敛 vs λₙ ≡ 1 发散）。

实弹：迹收敛的数值语义锚——λₙ = 1/n² 型特征值的
收敛趋势（S₁ 收费的机器版：前 10 项的部分和账）。
-/

open MeasureTheory ProbabilityTheory

/-! ## 零件正名 -/

#check @MeasureTheory.charFunDual

/-! ## 迹收敛的收费账（S₁ 的语义锚） -/

/-- 迹类条件的机器版（数值语义锚）：λₖ = 1/(k+1)² 的前
若干项部分和收敛（前 10 项 ≈ 1.55 < 2——部分和单调有界
的收敛趋势；完整收敛账的严格证明走单调有界原理，此处以
显式数值锚登记 S₁ 收费的具体面貌）。 -/
example : ∑ k ∈ Finset.range 10, (1 / ((k + 1 : ℚ)^2 : ℚ))
    = 1968329 / 1270080 := by
  norm_num [Finset.sum_range_succ]
