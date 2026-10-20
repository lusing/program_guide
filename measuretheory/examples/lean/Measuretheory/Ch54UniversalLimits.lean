import Mathlib.Probability.Distributions.Poisson.Basic
import Mathlib.Analysis.SpecialFunctions.Complex.LogBounds

/-!
# 第 54 章 普遍极限定理（Lean）

袁下册第 23 章。**分工如实**：mathlib 无无穷小阵列/普遍极限
定理基础设施（退化收敛准则、Khinchin-Feller-Gnedenko 主定理
均无形式化）——docs 承载理论本体。

本章机器侧旗舰：**Poisson 收编条款的代数心脏**——二项 →
Poisson 的特征函数逐点收敛：Bin(n, λ/n) 的 ch.f. 为
(1 + λ(e^{it}−1)/n)ⁿ，由**复合利息极限**
`tendsto_one_add_div_pow_exp`（(1+t/n)ⁿ → eᵗ）收敛到
exp(λ(e^{it}−1)) = Po(λ) 的 ch.f.（`charFun_map_cast_
poissonMeasure` 的闭式）——1837 年 Poisson 极限定理的
机器版全程。
-/

open MeasureTheory ProbabilityTheory Filter
open scoped Topology NNReal

/-! ## 锚点正名 -/

#check @charFun_conv
#check @charFun_map_cast_poissonMeasure
#check @Complex.tendsto_one_add_div_pow_exp

/-! ## Poisson 收编：代数心脏的机器证 -/

/-- **复合利息极限的实弹**：(1 + t/n)ⁿ → eᵗ（t = 1 的
数值无关判决——54.4 例 54.E 的分析引擎）。 -/
example : Tendsto (fun n : ℕ ↦ (1 + (1 : ℂ) / n) ^ n) atTop (𝓝 (Complex.exp 1)) :=
  Complex.tendsto_one_add_div_pow_exp 1

/-- **Poisson 收编的 ch.f. 收敛**：对每个固定 t，
Bin(n, λ/n) 的特征函数 (1 + λ(e^{it}−1)/n)ⁿ 逐点收敛到
exp(λ(e^{it}−1))——后者恰是 Po(λ) 的 ch.f.（charFun_map_
cast_poissonMeasure 的闭式）。"二项 → Poisson"在 mathlib
里的完全代数行程。 -/
theorem binomial_charFun_tendsto_poisson (lam : ℝ≥0) (t : ℝ) :
    Tendsto (fun n : ℕ ↦ (1 + (lam : ℂ) * (Complex.exp (t * Complex.I) - 1) / n) ^ n)
      atTop (𝓝 (Complex.exp (lam * (Complex.exp (t * Complex.I) - 1)))) :=
  Complex.tendsto_one_add_div_pow_exp _

/-- **闭式对账**：上定理的极限 = Po(λ) 的 ch.f. 在 t 处的
值（`charFun_map_cast_poissonMeasure`）——收编条款的两端
在同一表达式会合。 -/
example (lam : ℝ≥0) (t : ℝ) :
    Complex.exp ((lam : ℂ) * (Complex.exp (t * Complex.I) - 1))
      = charFun Po(ℝ, lam) t :=
  (charFun_map_cast_poissonMeasure lam t).symm
