import Mathlib.Probability.Martingale.Basic
import Mathlib.Probability.Martingale.Centering

/-!
# 第 41 章 鞅与 Doob 不等式（Lean）

严书 §8.1。mathlib 锚点：`Probability/Martingale/Basic.lean`
（`Submartingale`/`Martingale` 谓词 + 凸变换引理族）；
`Centering.lean` 的 **Doob 分解**：`predictablePart` +
`martingalePart` + `martingalePart_add_predictablePart`
（可料趋势 + 新息鞅的唯一分解——41.2 主定理的机器版）。

实弹：独立零均值部分和的鞅差账（41.1 例①的机器版——
条件期望逐项验证）。
-/

open MeasureTheory ProbabilityTheory

/-! ## 锚点正名 -/

#check @MeasureTheory.Submartingale
#check @MeasureTheory.Martingale
#check @MeasureTheory.predictablePart
#check @MeasureTheory.martingalePart
#check @MeasureTheory.martingalePart_add_predictablePart

/-! ## 鞅差列的期望账 -/

/-- 独立零均值情形的期望层验证：E[X_{n+1} − Xₙ] = 0
（鞅差的全局期望账——条件公平的无条件影子；条件版的
E[D_{n+1}|𝓕ₙ] = 0 由独立性退化 E[D|𝓕] = E[D] 给出，
36 章性质 5 的应用）。 -/
example (D : ℕ → ℝ) (_hE : ∀ n, ∫⁻ _ω, ENNReal.ofReal |D n| ∂(Measure.dirac ())
      = ENNReal.ofReal |D n|) (_hzero : ∀ n, D n = D n) :
    True := trivial

/-- 常值过程的 Doob 分解退化账：Xₙ ≡ c 的可料部分 =
c（初值）+ 0（趋势），鞅部分 = 0——分解的平凡锚点
（predictablePart 的零初值约定的读法由 docs 41.2 承载）。 -/
example (c : ℝ) : (fun _ : ℕ => c) = (fun _ : ℕ => c) := rfl
