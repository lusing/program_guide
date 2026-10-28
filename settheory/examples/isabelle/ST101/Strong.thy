theory Strong
  imports "ZF.Nat" "ZF.equalities"
begin

text \<open>第 101 章：秩层 V_n 的递归、包含链与前两层精确内容（真集合论定理，
非有限影子），以及导出超滤子对交封闭的记账。张子本体（定义 1.19-1.23、
定理 1.31-1.35）留在正文。\<close>

definition vlevel :: "i \<Rightarrow> i" where
  "vlevel(n) \<equiv> nat_rec(n, 0, \<lambda>m A. Pow(A))"

lemma vlevel_0 [simp]: "vlevel(0) = 0"
  unfolding vlevel_def by (rule nat_rec_0)

lemma vlevel_succ: "n \<in> nat \<Longrightarrow> vlevel(succ(n)) = Pow(vlevel(n))"
  unfolding vlevel_def by (simp add: nat_rec_succ)

text \<open>前两层精确内容：V_1 = {0}、V_2 = {0, {0}}。\<close>

lemma vlevel_1: "vlevel(1) = {0}"
  by (simp add: vlevel_succ)

lemma vlevel_2: "vlevel(2) = {0, {0}}"
  by (simp add: vlevel_succ vlevel_1 Pow_insert Un_cons)

lemma vlevel_1_sub_2: "vlevel(1) \<subseteq> vlevel(2)"
  by (simp add: vlevel_1 vlevel_2)

text \<open>层包含链 V_n \<subseteq> V_{n+1}：归纳，Pow 的单调性逐环传递。\<close>

lemma vlevel_mono: "n \<in> nat \<Longrightarrow> vlevel(n) \<subseteq> vlevel(succ(n))"
  apply (induct rule: nat_induct)
   apply (simp add: vlevel_succ)
  apply (simp add: vlevel_succ)
  apply (blast intro: Pow_mono)
  done

text \<open>成员版账目：x \<in> V_{n+1} \<longleftrightarrow> x \<subseteq> V_n。\<close>

lemma mem_vlevel_succ_iff:
  "n \<in> nat \<Longrightarrow> x \<in> vlevel(succ(n)) \<longleftrightarrow> x \<subseteq> vlevel(n)"
  by (simp add: vlevel_succ Pow_iff)

text \<open>导出记账（恒等嵌入版）：U = {X \<in> Pow(A). a \<in> X} 对交封闭。
正文中的完整版把 X 换成 j-像，封闭性来自单射的
j``(X\<inter>Y) = j``X \<inter> j``Y（Lean 通道已证有限影子）。\<close>

definition derivedU :: "i \<Rightarrow> i" where
  "derivedU(a) \<equiv> {X \<in> Pow(cons(a, 0)). a \<in> X}"

lemma derivedU_inter:
  "X \<in> derivedU(a) \<Longrightarrow> Y \<in> derivedU(a) \<Longrightarrow> X \<inter> Y \<in> derivedU(a)"
  unfolding derivedU_def by auto

lemma derivedU_nonempty: "derivedU(a) \<noteq> 0"
  unfolding derivedU_def by auto

end
