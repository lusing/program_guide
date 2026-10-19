import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.MeasureTheory.Integral.DominatedConvergence
import Mathlib.MeasureTheory.Integral.Lebesgue.Countable

/-!
# 第 16 章 Bochner 积分（Lean）

严书 §3.7。机器实情（第 10 章预告的兑现）：**mathlib 的
`MeasureTheory.integral` 就是 Bochner 积分**——Banach 值 G 上的
主接口（Integral/Bochner/Basic.lean:156，irreducible_def），第
10-11 章的实值实弹全是它的特例；第 11 章用的
`tendsto_integral_of_dominated_convergence` 本来就是**向量版**
DCT（G 为赋范群）——Bochner-DCT（习题 3.7.2）已在彼处实弹。

本文件锚点正名 + 两发向量实弹：ℝ×ℝ 值常值函数在 dirac 上的
积分；向量函数的强可测资格证。
-/

open MeasureTheory
open Filter
open scoped Topology ENNReal

/-! ## 锚点正名 -/

#check @MeasureTheory.integral
#check @MeasureTheory.AEStronglyMeasurable
#check @MeasureTheory.Integrable
#check @MeasureTheory.tendsto_integral_of_dominated_convergence

/-! ## 实弹：向量值积分 -/

/-- 向量值常值函数在狄拉克质量上的 Bochner 积分 = 该向量本身
（逐分量收割；注意 integral_dirac 的点 a 是显式第二参数）。 -/
example (v : ℝ × ℝ) :
    ∫ _ : Bool, v ∂(Measure.dirac true) = v :=
  integral_dirac (fun _ => v) true

/-- 连续向量函数强可测（ℝ×ℝ 上连续 ⇒ StronglyMeasurable ⇒
AEStronglyMeasurable 对任意测度；AEStronglyMeasurable 是 ∃ 定义，
证据三元组直接给；乘积连续性引理的现名是 prodMk（驼峰，非
prod_mk）。 -/
example (μ : Measure ℝ) :
    AEStronglyMeasurable (fun x : ℝ => (x, x ^ 2)) μ :=
  ⟨fun x => (x, x ^ 2),
    (continuous_id.prodMk (continuous_pow 2)).stronglyMeasurable,
    by simp⟩
