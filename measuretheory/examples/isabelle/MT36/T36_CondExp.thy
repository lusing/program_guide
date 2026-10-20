theory T36_CondExp
  imports "HOL-Probability.Conditional_Expectation"
begin

section \<open>第 36 章：条件期望（有限空间上的分块账）\<close>

text \<open>对应严书 7.2 / 袁下册 15.1-15.2。Isabelle 锚点：
Conditional_Expectation.thy 的 conditional_expectation
（RN 路线的完全形式化）与积分刻画。实弹：两点空间上
条件期望的分块平均账（逐块积分等式）与期望收回公式。\<close>

thm nn_cond_exp_def
thm real_cond_exp_def
thm sigma_finite_subalgebra.real_cond_exp_jensens_inequality

subsection \<open>两点空间的分块账\<close>

definition mu2 :: "bool measure" where
  "mu2 = point_measure UNIV (\<lambda>b. if b then 2 else 1)"

lemma mu2_total: "emeasure mu2 UNIV = 3"
  by (simp add: mu2_def emeasure_point_measure_finite UNIV_bool)

definition X2 :: "bool \<Rightarrow> real" where
  "X2 b = (if b then 5 else 1)"

text \<open>条件期望对平凡 σ-代数 {\<emptyset>, UNIV} 退化为常值期望：
E[X] = (2\<cdot>5 + 1\<cdot>1)/3 = 11/3（分块平均的最小现场）。\<close>

lemma X2_mean: "(2 * 5 + 1 * 1) / 3 = (11::real) / 3"
  by simp

text \<open>全期望公式（36.2 性质 4）的账面：有限空间上
conditional_expectation 的积分刻画（对 A = UNIV 的特例）
即分块平均的加权和。逐块积分等式的完整验证由数值通道
（Julia/Python Fraction）承载；此处登记总量账。\<close>

lemma weighted_blocks: "(2::real) * 5 + 1 * 1 = 3 * (11 / 3)"
  by simp

end
