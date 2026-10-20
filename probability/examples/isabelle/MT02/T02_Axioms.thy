theory T02_Axioms
  imports "HOL-Probability.Probability"
begin

section \<open>第 02 章：概率公理与基本定律（Isabelle 锚点）\<close>

text \<open>对应 Miller ch2。Isabelle/HOL-Probability 的公理化：
measure_space locale（可测空间 + 可数可加的 emeasure）就是
Kolmogorov 三公理（非负/规范/可数可加）的化身。本章登记
"免费午餐"四条的机器原文（正文 02.4 的推导逐一对应）：

- emeasure_empty：μ ∅ = 0（正文 02.C）；
- plus_emeasure：不交并的可加（02.E 容斥的基件）；
- emeasure_compl：补律 μ A^c = μ Ω − μ A（02.B）；
- emeasure_subadditive：Boole 上界（02.G）。\<close>

subsection \<open>锚点正名\<close>

thm emeasure_empty
thm plus_emeasure
thm emeasure_compl
thm emeasure_subadditive

text \<open>读法：emeasure 取值于 ennreal（ℝ≥0∞）——非负性与
规范性内建于类型；prob_space locale 再加 μ Ω = 1（本科
概率空间）。measure（实值侧）的对应版本在 finite_measure
locale（如 finite_measure.finite_measure_compl）。两套
（Lean 的 measure_mono/measure_compl 族与 Isabelle 的
plus_emeasure/emeasure_compl 族）是同一组公理推论的两份
独立实现——正文 02.5 的"两套公理系统，同一组免费午餐"。\<close>

end
