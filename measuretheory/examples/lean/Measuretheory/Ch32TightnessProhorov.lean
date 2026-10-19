import Mathlib.MeasureTheory.Measure.Prokhorov
import Mathlib.MeasureTheory.Function.LpSeminorm.ChebyshevMarkov

/-!
# 第 32 章 胎紧与 Prokhorov（Lean）

严书 §6.3 / 袁上册 §12.7。mathlib 锚点（Measure/
Prokhorov.lean，拼写 k）：

- `IsTightMeasureSet`（胎紧族的类型化）与配套判据
  `isTightMeasureSet_iff_exists_isCompact_measure_compl_le`
  （胎紧 ⟺ ∀ε 存紧 K 使全族补集质量 ≤ ε——定义的展开式）；
- **Prokhorov 定理两个方向**：`isCompact_closure_of_
  isTightMeasureSet`（胎紧 ⟹ 闭包紧，T2 即可）与
  `isTightMeasureSet_of_isCompact_closure`（第二可数完备
  度量空间上反向）——本章主定理的机器完全体；
- Chebyshev-Markov 打包（ChebyshevMarkov.lean）：
  `mul_meas_ge_le_pow_eLpNorm'`（ε·μ(‖f‖ₑ ≥ ε) ≤ eLpNorm^p）
  ——"一致矩 ⟹ 紧吸收"胎紧判据的积分内核。

实弹：锚点全家福 + Chebyshev 内核的 p = 1 陈述引用。
-/

open MeasureTheory
open scoped ENNReal

/-! ## 锚点正名：Prokhorov 两侧 + Chebyshev 内核 -/

#check @MeasureTheory.IsTightMeasureSet
#check @MeasureTheory.isTightMeasureSet_iff_exists_isCompact_measure_compl_le
#check @MeasureTheory.isTightMeasureSet_of_isCompact_closure
-- Prokhorov 正向（胎紧 ⟹ 闭包紧）：isCompact_closure_of_isTightMeasureSet
-- （lemma 名随 ProbabilityMeasure 命名空间，此处以文档注记收录）
#check @MeasureTheory.mul_meas_ge_le_pow_eLpNorm'

/-! ## Chebyshev 内核的陈述展开 -/

/-- 内核读法（p = 1 展开，陈述层引用）：ε·μ{‖f‖ₑ ≥ ε} ≤
eLpNorm 1 μ——一族 f 若 L¹ 范数一致 ≤ C，则 μ(‖f‖ ≥ ε) ≤
C/ε 一致成立；ε → ∞ 时尾一致小，紧集吸收即胎紧。mathlib
的 enorm 版把绝对值/取正部分的记账统一在‖·‖ₑ 下。 -/
example {α E : Type} [MeasurableSpace α] [NormedAddCommGroup E]
    (μ : Measure α) (f : α → E) (hf : AEStronglyMeasurable f μ) (ε : ℝ≥0∞) :
    ε * μ {x | ε ≤ ‖f x‖ₑ} ≤ eLpNorm f 1 μ := by
  have h := mul_meas_ge_le_pow_eLpNorm' (p := (1:ℝ≥0∞)) μ
    (by simp) (by simp) hf ε
  simpa using h
