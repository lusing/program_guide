theory T21_CLT
  imports "HOL-Probability.Probability_Mass_Function"
begin

text \<open>
  第 21 章（Miller ch20）CLT 的 Isabelle 侧：标准化的矩账
  （有限情形的 pmf_of_set 组合）与 n 重和的方差可加原型。
\<close>

subsection \<open>标准化的矩账：有限两点的原型\<close>

text \<open>伯努利型两点 {0,1} 等概率：均值 1/2、方差 1/4——标准化
  Z = 2X−1 的方差为 1 的账。\<close>

lemma two_point_mean:
  "integral\<^sup>L (measure_pmf (pmf_of_set {0, 1})) real = 1/2"
  by (simp add: integral_pmf_of_set)

lemma two_point_second:
  "integral\<^sup>L (measure_pmf (pmf_of_set {0, 1})) (\<lambda>k. (real k) ^ 2) = 1/2"
  by (simp add: integral_pmf_of_set)

text \<open>方差 = 1/2 − (1/2)^2 = 1/4；标准差 1/2。\<close>

lemma two_point_var: "(1/2::real) - (1/2)^2 = 1/4"
  by (simp add: power2_eq_square)

subsection \<open>n 重和的方差可加：两骰原型\<close>

text \<open>单骰方差 35/12（第 8 章账）；两独立骰之和方差 2·35/12
  = 35/6（第 10 章独立可加的复用）。\<close>

lemma die_var: "(91/6::real) - (7/2)^2 = 35/12"
  by (simp add: power2_eq_square)

lemma two_dice_var: "2 * (35/12::real) = 35/6"
  by (simp add: field_simps)

end
