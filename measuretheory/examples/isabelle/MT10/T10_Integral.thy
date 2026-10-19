theory T10_Integral
  imports "HOL-Analysis.Analysis"
begin

section \<open>第 10 章：积分的三步构造（有限格上的精确账）\<close>

text \<open>对应严书 3.1。Isabelle 的 nn_integral（非负值，即教程里的
lintegral）与 Bochner integral^L 都按 API 使用。第一步的钥匙是
nn_integral_indicator（simp 引理：指示函数积分 = 测度），有限
计数空间上一切账目归约为 emeasure 的逐项计算。\<close>

subsection \<open>第一步：示性函数的积分 = 测度\<close>

lemma lintegral_indicator_count:
  "(\<integral>\<^sup>+x. indicator {1::nat} x \<partial>count_space {0,1}) = 1"
  by simp

subsection \<open>第二步：非负线性与单调（齐次 + 可加）\<close>

lemma lintegral_linear_count:
  "(\<integral>\<^sup>+x. 2 * indicator {1::nat} x + 3 * indicator {0::nat} x
      \<partial>count_space {0,1}) = 5"
  by (simp add: nn_integral_add nn_integral_cmult)

lemma lintegral_mono_count:
  "(\<integral>\<^sup>+x. indicator {1::nat} x \<partial>count_space {0,1})
   \<le> (\<integral>\<^sup>+x. indicator {0::nat} x + indicator {1::nat} x \<partial>count_space {0,1})"
  by (simp add: nn_integral_add)

subsection \<open>Markov 不等式（指示版内核，偏差集已算出）\<close>

lemma markov_deviation_set:
  fixes a :: ennreal
  assumes "0 < a" "a \<le> 1"
  shows "{x::nat. a \<le> indicator {1::nat} x} = {1}"
  using assms by (auto simp: indicator_def split: if_splits)

lemma markov_count:
  fixes a :: ennreal
  assumes "0 < a" "a \<le> 1"
  shows "a * emeasure (count_space {0,1::nat}) {x. a \<le> indicator {1::nat} x}
         \<le> (\<integral>\<^sup>+x. indicator {1::nat} x \<partial>count_space {0,1})"
proof -
  have "{x::nat. a \<le> indicator {1::nat} x} = {1}"
    using assms by (auto simp: indicator_def split: if_splits)
  then show ?thesis
    using assms(2) by simp
qed

end
