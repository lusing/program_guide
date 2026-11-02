theory T12_DiscreteDists
  imports "HOL-Probability.Probability_Mass_Function"
begin

text \<open>
  第 12 章离散分布族的 Isabelle 侧：PMF 库的
  分布族锚点正名（bernoulli / geometric / poisson / pmf_of_set），
  离散均匀的期望与二阶矩账（integral_pmf_of_set 供账）。
\<close>

subsection \<open>锚点正名：PMF 分布族\<close>

lemma bernoulli_anchor: "pmf (bernoulli_pmf (1/2)) True = 1/2"
  by simp

lemma pmf_family_anchors:
  "pmf (bernoulli_pmf (1/3)) False = 2/3"
  by simp

subsection \<open>离散均匀：骰子的期望与二阶矩\<close>

lemma die_mean: "integral\<^sup>L (measure_pmf (pmf_of_set {1,2,3,4,5,6})) real = 7/2"
  by (simp add: integral_pmf_of_set)

lemma die_moment2:
  "integral\<^sup>L (measure_pmf (pmf_of_set {1,2,3,4,5,6})) (\<lambda>k. (real k)\<^sup>2) = 91/6"
  by (simp add: integral_pmf_of_set)

text \<open>方差捷径：91/6 - (7/2)^2 = 35/12。\<close>

lemma die_var: "(91/6::real) - (7/2)^2 = 35/12"
  by (simp add: field_simps power2_eq_square)

text \<open>离散均匀 {a..a+n-1} 的均值公式采样：{1,2,3,4,5,6,7,8,9} 的均值 = 5
  （a + (n-1)/2 的 a=1、n=9 形态）。\<close>

lemma uniform9_mean:
  "integral\<^sup>L (measure_pmf (pmf_of_set {1,2,3,4,5,6,7,8,9})) real = 5"
  by (simp add: integral_pmf_of_set)

end
