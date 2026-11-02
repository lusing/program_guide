import Mathlib.Tactic

/-!
# 第 29 章：渐近拼接的代数锚

`Op/op`、连续映射和 Slutsky 的定理陈述与证明在正文中；这里只验证
Delta 方法的方差系数、插入标准误的约分以及导数为零时的尺度变化。
-/

namespace Ch29

/-- 一阶 Delta 方差就是导数平方乘原渐近方差。 -/
def deltaVariance (derivative baseVariance : ℚ) : ℚ :=
  derivative ^ 2 * baseVariance

/-- `g(μ)=μ²`：导数为 `2μ`，渐近方差为 `4μ²σ²`。 -/
theorem delta_square (μ σ2 : ℚ) :
    deltaVariance (2 * μ) σ2 = 4 * μ ^ 2 * σ2 := by
  simp only [deltaVariance]
  ring

/-- Poisson 均值开方：`(1/(2√p))²·p=1/4`，用有理数 `q=√p` 表达。 -/
theorem delta_poisson_sqrt (q : ℚ) (hq : q ≠ 0) :
    deltaVariance (1 / (2 * q)) (q ^ 2) = 1 / 4 := by
  simp only [deltaVariance]
  field_simp
  ring

/-- Bernoulli logit：导数为 `1/(p(1-p))`，故方差系数为其倒数。 -/
theorem delta_logit (p : ℚ) (hp : p ≠ 0) (hp1 : 1 - p ≠ 0) :
    deltaVariance (1 / (p * (1 - p))) (p * (1 - p)) =
      1 / (p * (1 - p)) := by
  simp only [deltaVariance]
  field_simp

/-- Slutsky 插入标准误的代数核心：同一非零因子相除后抵消。 -/
theorem plugin_cancel (a b c : ℚ) (hb : b ≠ 0) (hc : c ≠ 0) :
    (a / b) * (b / c) = a / c := by
  field_simp

/-- 二阶退化的系数：`g(x)=x²` 的二阶导数除以 `2!` 等于 1。 -/
example : (2 : ℚ) / 2 = 1 := by norm_num

end Ch29
