import Mathlib.Probability.StrongLaw
import Mathlib.Probability.BorelCantelli
import Mathlib.MeasureTheory.Function.LpSeminorm.ChebyshevMarkov

/-!
# 第 56 章 重对数律（Lean）

袁下册第 25 章。**分工如实**：mathlib 无 Hartman-Wintner
重对数律（无 iterated logarithm 基础设施、无三常数定理）
——docs 承载四步证明解剖。

本章机器侧零件：**Borel-Cantelli 两引理的正名**（第一引理
`measure_limsup_atTop_eq_zero` 是 LIL 上界"缴 B-C 入场费"
一步的现成件；第二引理 `measure_limsup_eq_one` 是下界证明
的独立性引擎——两件在此会师正是 56.3 四步解剖的引擎房）+
尾估计引擎（`mul_meas_ge_le_pow_eLpNorm'`，48 章件）+
`strong_law_ae` 对照（LIL 是 SLLN 的精修）。
-/

open MeasureTheory ProbabilityTheory Filter
open scoped ENNReal

/-! ## Borel-Cantelli 两引理：LIL 的引擎房 -/

#check @MeasureTheory.measure_limsup_atTop_eq_zero
#check @measure_limsup_eq_one

/-- **第一引理的实弹**：几何衰减的事件序列
P{Aₙ} = 2⁻ⁿ ⟹ P{Aₙ i.o.} = 0——LIL 上界（包络系数 >1 时
轨道只越界有限次）的入场费结算原型。 -/
example {Ω : Type*} [MeasureSpace Ω] (A : ℕ → Set Ω)
    (h : ∀ n, ℙ (A n) = (2 : ℝ≥0∞)⁻¹ ^ n) :
    ℙ (Filter.limsup A atTop) = 0 := by
  refine MeasureTheory.measure_limsup_atTop_eq_zero ?_
  rw [funext h]
  have h1 : (2 : ℝ≥0∞)⁻¹ < 1 := by norm_num
  rw [ENNReal.tsum_geometric _]
  norm_num

/-! ## 对照锚点：LIL 的两位邻居 -/

#check @ProbabilityTheory.strong_law_ae
#check @MeasureTheory.mul_meas_ge_le_pow_eLpNorm'

/-- 尾估计引擎的形态引用：LIL 四步解剖的第 3 步（对称化 +
尾概率估计）在 mathlib 里的对应零件是 Chebyshev 型指数矩界
（陈述登记——正态和上的具体形式由数值通道对拍）。 -/
example {α : Type} [MeasurableSpace α] (μ : Measure α) (f : α → ℝ)
    (hf : AEStronglyMeasurable f μ) (ε : ℝ≥0∞) :
    ε * μ {x | ε ≤ ‖f x‖ₑ} ≤ eLpNorm f 1 μ := by
  have h := mul_meas_ge_le_pow_eLpNorm' (p := (1 : ℝ≥0∞)) μ
    (by simp) (by simp) hf ε
  simpa using h
