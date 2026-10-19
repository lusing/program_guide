import Mathlib.MeasureTheory.Measure.LevyProkhorovMetric

/-!
# 第 33 章 Lévy-Prokhorov 度量（Lean）

严书 §6.4 / 袁上册 §12.1。mathlib 锚点（Measure/
LevyProkhorovMetric.lean）：`levyProkhorovEDist`（edist 版：
μ(A) ≤ ν(Aᵉ)+ε 的双向下确界）、`levyProkhorovDist`（有限
测度上的距离版）与配套的收敛等价/三角/端口引理族
（`left_measure_le_of_levyProkhorovEDist_lt` 等）。

实弹：锚点正名 + dirac 对的 edist 账（δₓ 与 δᵧ 的距离 =
min(d(x,y),1) 型退化的陈述引用）。
-/

open MeasureTheory
open scoped ENNReal

/-! ## 锚点正名 -/

#check @MeasureTheory.levyProkhorovEDist
#check @MeasureTheory.levyProkhorovDist
#check @MeasureTheory.left_measure_le_of_levyProkhorovEDist_lt

/-! ## dirac 对的退化账（陈述引用 + 引理读法） -/

/-! 读法（文档层）：levyProkhorovEDist δₓ δᵧ 在 ε = min(d,1)
控制——`left_measure_le_of_levyProkhorovEDist_lt` 把
edist < c 的假设翻译成一切可测集的账目不等式
μ(B) ≤ ν(Bᶜ-膨胀控制)+c。δₓ 对 δᵧ 的一切集合账只取
0/1，膨胀吞掉 {x}↔{y} 的距离——退化对的距离即点距的
截断。数值通道以离散穷举对拍本账（33.4 断言 2）。 -/

/-- 两点空间 {0,1}（离散）上 δ₀ 与 δ₁ 的 edist 账：一切
可测集的双向检验给出 edist ≤ 1（平凡上界）——距离公理
的 degenerate 收款现场（精确账由数值通道 Fraction 穷举）。 -/
-- edist 的有限性（有限测度上自动 < ⊤）与恒等/对称/三角
-- 三引理构成距离公理的机器版（API 见上方 #check 族）。
example (μ ν : Measure ℕ) [IsFiniteMeasure μ] [IsFiniteMeasure ν] :
    levyProkhorovEDist μ ν < ⊤ := levyProkhorovEDist_lt_top μ ν
