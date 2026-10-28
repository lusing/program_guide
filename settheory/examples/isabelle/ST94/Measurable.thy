theory Measurable
  imports "ZF.Nat"
begin

text \<open>第 94 章：三元素集上的主超滤。这里的 principal 是有限退化
模型，不具有可测基数定义中的非平凡性、κ-完全性和正规性。\<close>

definition K3 :: "i" where "K3 \<equiv> succ(succ(succ(0)))"
definition P0 :: "i" where "P0 \<equiv> {A \<in> Pow(K3). 0 \<in> A}"

lemma P0_mem: "A \<in> Pow(K3) \<Longrightarrow> A \<in> P0 \<longleftrightarrow> 0 \<in> A"
  by (simp add: P0_def)

lemma P0_full: "K3 \<in> P0"
  by (auto simp add: P0_def K3_def)

lemma P0_empty: "0 \<notin> P0"
  by (simp add: P0_def)

lemma P0_inter: "A \<in> P0 \<Longrightarrow> B \<in> P0 \<Longrightarrow> A \<inter> B \<in> P0"
  by (auto simp add: P0_def)

lemma P0_upward: "A \<in> P0 \<Longrightarrow> A \<subseteq> B \<Longrightarrow> B \<subseteq> K3 \<Longrightarrow> B \<in> P0"
  by (auto simp add: P0_def)

lemma P0_decides: "A \<subseteq> K3 \<Longrightarrow> A \<in> P0 \<or> (K3-A) \<in> P0"
  by (auto simp add: P0_def K3_def)

lemma P0_singleton: "{0} \<in> P0"
  by (auto simp add: P0_def K3_def)

end
