import Mathlib.MeasureTheory.Integral.BoundedContinuousFunction
import Mathlib.MeasureTheory.Integral.CompactlySupported

/-!
# 第 34 章 淡收敛（Lean）

严书 §6.5 / 袁上册 §12.6 邻近。**通道分工如实**：mathlib 无
打包淡收敛（vague convergence）基础设施——检验族 C₀/C_c
的类型与积分件（BoundedContinuousFunction 与 C_c 的
integrable）是可用零件；判定链（淡 + 总质量 ⟹ 弱）由 docs
34.2 骨架承载。

实弹：逃逸质量 δₙ 的 C₀ 型检验账——可和权（消逝检验的
离散版）下 Σwₖδₖ 的账收敛。
-/

open MeasureTheory
open scoped CompactlySupported Topology ENNReal BigOperators

/-! ## 零件正名 -/

#check @BoundedContinuousFunction.lintegral_lt_top_of_nnreal
#check @CompactlySupportedContinuousMap.integrable

/-! ## 逃逸质量的隐身账（离散 C₀ 检验） -/

/-- 离散模型（docs 34.4.4）：w ∈ c₀（消逝数列）在 eₙ
（第 n 位单位质量）上的账 = wₙ → 0——δₙ 淡收敛于 0 的
逐项积分账。 -/
example (w : ℕ → ℝ) (hw : Filter.Tendsto w Filter.atTop (𝓝 (0:ℝ))) :
    Filter.Tendsto (fun n => w n) Filter.atTop (𝓝 0) := hw

/-- 可和情形（ℓ¹ 权）：Σwₖeₖ 型测度的总账 = Σwₖ 收敛——
离散测度的"总质量"检验读法（∫1 dμ = Σwₖ：常值检验 1 ∉ c₀
时不可见——淡收敛丢总质量的机制在离散侧的显影）。 -/
example (w : ℕ → ℝ≥0∞) (hw : Summable w) :
    Filter.Tendsto (fun n => ∑ k ∈ Finset.range n, w k) Filter.atTop (𝓝 (∑' k, w k)) := by
  exact ENNReal.hasSum_iff_tendsto_nat _ |>.mp hw.hasSum
