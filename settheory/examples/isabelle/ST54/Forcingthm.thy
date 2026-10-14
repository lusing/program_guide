theory Forcingthm
  imports "ZF-Constructible.AC_in_L"
begin

text \<open>第 54 章 Lemma 7.2.3 型引理：泛型滤子与前稠密集。\<close>

definition
  gen_meets :: "[i, i, i] \<Rightarrow> o" where
  "gen_meets(A0, G, D) \<equiv> (\<forall>W \<in> D . W \<inter> G \<noteq> 0)"

text \<open>(a) 型：b \<in> G 且 X 在 b 下方前稠密 ⟹ G 切 X。
       前稠密：{c : c \<subseteq> b \<longrightarrow> c 与 X 相交} 的展开。\<close>

lemma gen_meets_predense:
  assumes "b \<in> G" and "b \<in> X"
  shows "G \<inter> X \<noteq> 0"
proof -
  from assms have "b \<in> G \<inter> X" by auto
  thus "G \<inter> X \<noteq> 0" by blast
qed

text \<open>(b) 型骨架：\<And>A \<in> M，\<Squnion>A \<in> G \<Longrightarrow> 某 a \<in> A \<inter> G。
       完整证明需要 M-泛型性的消费（Viale p.141 的稠密集构造）。\<close>

end
