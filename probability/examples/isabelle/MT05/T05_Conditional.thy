theory T05_Conditional
  imports "HOL-Probability.Probability"
begin

section \<open>第 05 章：条件概率与 Bayes（Isabelle 锚点）\<close>

text \<open>对应 Miller ch4。HOL-Probability 的条件概率：
`conditional_prob`（实值定义 P(B|A) = P(A\<inter>B)/P(A)）与
乘法/Bayes 的可用件。与 Lean 侧 ProbabilityTheory.cond
（条件测度）是同一概念的两种户口。\<close>

subsection \<open>锚点正名\<close>

thm cond_prob_def
thm prob_space.cond_prob_eq_AE

text \<open>读法：conditional_prob 在 prob_space locale 下展开为
测度商；Bayes 的形式（先验\<times>似然/证据）与 Lean 侧
cond_eq_inv_mul_cond_mul 互译。数值账（医学检验 19/1018、
Monty Hall 2/3）由 Julia/Python/Prolog 三通道承载。\<close>

end
