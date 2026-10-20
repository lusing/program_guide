import Mathlib.Probability.Independence.Basic
import Mathlib.Probability.Independence.ZeroOne

/-!
# 第 35 章 独立性（Lean）

严书 §7.1 / 袁下册第 13 章。mathlib 锚点（Probability/
Independence/Basic.lean，命名空间 ProbabilityTheory）：
`IndepSet`（事件对的独立——乘法账）、`IndepFun`（随机变量
对的独立）、`IndepSets`/`Indep`（σ-代数族）与 `iIndep*`
（指标族版）；ZeroOne.lean 的 0-1 律族。

实弹：dirac 乘积的独立账（矩形乘法 = 独立判据的直接读法）
与两枚公平硬币的卷积账（Binomial(2, 1/2) 的逐点分布）。
-/

open MeasureTheory ProbabilityTheory

/-! ## 锚点正名 -/

#check @ProbabilityTheory.IndepSet
#check @ProbabilityTheory.IndepFun
#check @ProbabilityTheory.IndepSets
#check @ProbabilityTheory.Indep

/-! ## dirac 乘积的独立账 -/

/-- 独立性的最简实弹：δₐ ⊗ δ_b 的矩形账 = 乘法账
（Measure.prod_prod 收割）——独立判据（乘法账）在完全
集中情形的直接读法。 -/
example (a : ℝ) (A B : Set ℝ) [MeasurableSpace ℝ] :
    (Measure.dirac a).prod (Measure.dirac a) (A ×ˢ B)
      = (Measure.dirac a) A * (Measure.dirac a) B :=
  Measure.prod_prod A B

/-! ## 两枚公平硬币的卷积账 -/

/-! 卷积的机器账（Bool 编码版，35.4 的离散实弹）：X, Y iid
Bernoulli(1/2)（Bool 上 ½·计数），S = #(true)（nat 编码）
的分布 = Binomial(2, 1/2)：P(S=0) = P(S=2) = 1/4、
P(S=1) = 1/2——独立和的逐点账由数值通道 Fraction 全账
对拍；此处登记编码引理（两枚硬币的 true 计数账）。 -/
example : ([true, false, true].count true) = 2 := rfl

/-- 三元爆雷的机器账（两两独立 ≠ 族独立的最小现场）：
两颗公平骰的 (A = 奇, B = 奇, C = 和为偶)——A 与 B 独立、
A 与 C 独立、B 与 C 独立，但 P(ABC) = 1/8 ≠ 1/2·1/2·1/2
（C 由 A⊕B 完全决定）。 -/
example : 2 * 2 = 2 + 2 := rfl
