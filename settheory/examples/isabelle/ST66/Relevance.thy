theory Relevance
  imports "ZF.EquivClass"
begin

text \<open>第 66 章：相关性（Makinson Ch11）。变量共享的集合级骨架。\<close>

definition shares :: "[i,i] \<Rightarrow> o" where
  "shares(A,B) \<equiv> A \<inter> B \<noteq> 0"

lemma no_share_empty: "\<lbrakk>A = 0; B = {0}\<rbrakk> \<Longrightarrow> \<not> shares(A,B)"
  unfolding shares_def by auto

lemma share_nonempty: "shares({0,1},{1,2})"
  unfolding shares_def by blast

end
