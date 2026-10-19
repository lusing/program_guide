theory T00_Intro
  imports "HOL-Analysis.Analysis"
begin

text \<open>第 00 章导言的 Isabelle 冒烟：验证 HOL-Analysis 加载与测度 API。
真正的形式化内容从 B1（01 章）开始逐批加入。\<close>

lemma measure_empty_smoke: "emeasure (count_space (UNIV :: nat set)) {} = 0"
  by simp

lemma count_space_singleton: "emeasure (count_space (UNIV :: nat set)) {3} = 1"
  by simp

text \<open>测度的单调性：count_space 是 Pow 上的测度，单调性即 emeasure_mono。\<close>

lemma measure_mono_smoke:
  fixes A B :: "nat set"
  assumes "A \<subseteq> B"
  shows "emeasure (count_space UNIV) A \<le> emeasure (count_space UNIV) B"
proof -
  have "B \<in> sets (count_space UNIV)" by auto
  then show ?thesis by (rule emeasure_mono[OF assms])
qed

end
