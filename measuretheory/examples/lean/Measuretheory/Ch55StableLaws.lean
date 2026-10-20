import Mathlib.Probability.Distributions.Cauchy
import Mathlib.Probability.Distributions.Pareto

/-!
# 第 55 章 稳定分布（Lean）

袁下册第 24 章。**分工如实**：mathlib 无稳定分布基础设施
（无 StableDistribution、无稳定 ch.f. exp(−γ|t|^α)、无
广义 CLT）——docs 承载理论本体（四特征、α≤2 第一性证明、
尾平衡双充要）。

本章机器侧：mathlib 的**Cauchy 与 Pareto 测度实现**两锚点
正名 + 实弹两件——① Cauchy 密度的归一积分（无期望分布的
完美归一——α=1 稳定律的第一公民）；② Pareto 的 cdf 公式
（广义 CLT 尾平衡的母体实现：r = α 的 Pareto 正是
P{X>x} ~ c·x^{−α} 的标准重尾）。
-/

open MeasureTheory ProbabilityTheory
open scoped NNReal

/-! ## 锚点正名 -/

#check @cauchyMeasure
#check @integral_cauchyPDFReal_eq_one
#check @paretoMeasure
#check @cdf_paretoMeasure_eq_lintegral

/-! ## Cauchy：α=1 稳定律的第一公民 -/

/-- **Cauchy 密度的归一实弹**：∫ 1/(π(1+x²))dx = 1——
EX 不绝对收敛（|x|·密度 ~ 1/|x| 双尾发散）却完美归一。
α=1 稳定律（Sₙ/n ≡ Cauchy）的机器侧户口。 -/
example {γ : ℝ≥0} (hγ : γ ≠ 0) : ∫ x, cauchyPDFReal 0 γ x = 1 :=
  integral_cauchyPDFReal_eq_one 0 hγ

/-- 尺度参数的显式形：γ = 1 的密度在 0 处 = 1/π
（标准 Cauchy 的峰值——数值通道对拍的锚点值）。 -/
example : cauchyPDFReal 0 1 0 = 1 / Real.pi := by
  simp [cauchyPDFReal]

/-! ## Pareto：广义 CLT 尾平衡的母体 -/

/-- **Pareto cdf 实弹**：F(x) = ∫_{(−∞,x]} 密度——r = α 时
P{X > x} = (t/x)^α = t^α·x^{−α} 正是尾平衡 n·P{X>aₙ} → c
的标准输入（55.3 定理 55.D 的母体）。 -/
example (t r : ℝ) (ht : 0 < t) (hr : 0 < r) (x : ℝ) :
    cdf (paretoMeasure t r) x = ENNReal.toReal (∫⁻ y in Set.Iic x, paretoPDF t r y) :=
  cdf_paretoMeasure_eq_lintegral ht hr x
