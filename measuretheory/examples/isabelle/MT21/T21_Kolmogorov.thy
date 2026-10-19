theory T21_Kolmogorov
  imports "HOL-Probability.Projective_Limit"
begin

section \<open>第 21 章：Kolmogorov 相容性与 Tulcea 定理\<close>

text \<open>对应严书 4.5。Isabelle 侧的分工：**Kolmogorov 引擎**——
Projective_Limit.thy 的 projective_family locale（相容族）与
polish_projective.lim（Daniell-Kolmogorov 存在性定理：Polish 值
相容族有无穷维极限测度）。这里给出均匀硬币乘积族的**相容性
实弹**（distr_restrict：有限窗分布 = 大窗的边缘）与存在性定理
的陈述引用；Tulcea 引擎（核列装配）的机器版在 Lean 侧
IonescuTulcea（docs 21.6）。注意两点实测纪律：全局
interpretation 在本版触发子 locale 注册事故，须用证明内局部
interpret（且带两参：M 与指标集 I）。\<close>

definition coin :: "bool measure" where
  "coin = uniform_count_measure (UNIV::bool set)"

lemma prob_space_coin: "prob_space coin"
  by (simp add: coin_def prob_space_uniform_count_measure)

subsection \<open>相容性实弹：乘积族的边缘一致\<close>

text \<open>相容性（projective_family 的核心公理）：有限窗 J 的分布 =
大窗 H 的边缘。product_prob_space.distr_restrict 恰是这条公理
在乘积族上的现成证明——"同一条样本轨道，两层窗的账一致"。\<close>

lemma coin_family_consistent:
  assumes "J \<subseteq> H" "finite H"
  shows "PiM J (\<lambda>_::nat. coin)
      = distr (PiM H (\<lambda>_::nat. coin)) (PiM J (\<lambda>_::nat. coin)) (\<lambda>f. restrict f J)"
proof -
  interpret CP: product_prob_space "(\<lambda>_::nat. coin)" "H::nat set"
    by (intro product_prob_spaceI) (simp add: prob_space_coin)
  show ?thesis using assms
    by (rule CP.distr_restrict)
qed

subsection \<open>存在性：Daniell-Kolmogorov 的陈述引用\<close>

text \<open>polish_projective = projective_family + Borel/Polish 值空间。
核心定理 emeasure_lim_emb：极限测度 lim 在柱集 emb I J X 上的账
= 有限维账 P J X——无穷维测度存在且逐柱集对账（lim 的构造走
finmap 紧化 + 对角线，正是严书 §4.5 紧类论证的 Isabelle 版）。
乘积族特例 limP_eq_PiM：极限 = PiM。\<close>

thm projective_family.P
thm polish_projective.emeasure_lim_emb
thm polish_product_prob_space.limP_eq_PiM

end
