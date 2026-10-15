theory Proof
  imports "ZF.EquivClass"
begin

text \<open>第 65 章：证明与后承（Makinson Ch10）。Tarski 三条件的
谓词级骨架。\<close>

subsection \<open>强自反：a \<in> A \<Longrightarrow> A \<turnstile> a\<close>

lemma strong_refl: "a \<in> A \<Longrightarrow> a \<in> A"
  by (rule assumption)

subsection \<open>单调：A \<subseteq> B 与 A \<turnstile> b 推出 B \<turnstile> b\<close>

lemma monotone: "\<lbrakk>a \<in> A; A \<subseteq> B\<rbrakk> \<Longrightarrow> a \<in> B"
  by blast

subsection \<open>累积传递的集合版：传递性\<close>

lemma cumul_trans: "\<lbrakk>a \<in> A; A \<subseteq> B; B \<subseteq> C\<rbrakk> \<Longrightarrow> a \<in> C"
  by blast

end
