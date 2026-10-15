theory Trees
  imports "ZF.EquivClass"
begin

text \<open>第 62 章：树（Makinson Ch7）。有限树的关系式骨架：
唯一父谓词及其否定方向的展开。\<close>

definition chainR :: i where
  "chainR \<equiv> {\<langle>0,1\<rangle>, \<langle>1,2\<rangle>}"

definition at_most_one_parent :: "[i,i] \<Rightarrow> o" where
  "at_most_one_parent(T,R) \<equiv>
     \<forall>x\<in>T. \<forall>y\<in>T. \<forall>z\<in>T.
       \<langle>y,x\<rangle> \<in> R \<and> \<langle>z,x\<rangle> \<in> R \<longrightarrow> y = z"

lemma chain_edges: "chainR = {\<langle>0,1\<rangle>, \<langle>1,2\<rangle>}"
  unfolding chainR_def by (rule refl)

text \<open>加一条边破坏唯一父：两父 z \<noteq> y 时谓词为假——
  展开定义、假设直接给出矛盾。\<close>

lemma amp_neg_unfold:
  assumes hy: "\<langle>y,x\<rangle> \<in> R" and hz: "\<langle>z,x\<rangle> \<in> R"
      and ne: "y \<noteq> z" and inT: "x \<in> T" "y \<in> T" "z \<in> T"
  shows "\<not> at_most_one_parent(T,R)"
  unfolding at_most_one_parent_def using assms by blast

end
