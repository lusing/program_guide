theory Woodin
  imports "ZF.Nat" "ZF.equalities"
begin

text \<open>第 102 章：f-闭包点（定义 1.25(i) 影子）、闭包的迭代传递性
与「见证必须随函数变化」的分离对（c1/c2）。后继函数无闭包点的
核心反例由 Lean/Coq/Agda 通道承载；武丁本体（定义 1.24/1.25、
定理 1.36-1.38）留在正文。\<close>

definition closedpt :: "[i\<Rightarrow>i, i] \<Rightarrow> o" where
  "closedpt(f, k) \<equiv> \<forall>i. i < k \<longrightarrow> f(i) < k"

text \<open>闭包的迭代传递性：闭包点对 f 的迭代也闭包
（f``k \<subseteq> k ⟹ f\<circ>f``k \<subseteq> k）。\<close>

lemma closedpt_iter:
  assumes "closedpt(f, k)" shows "closedpt(\<lambda>x. f(f(x)), k)"
  using assms unfolding closedpt_def by auto

text \<open>分离对：常值函数 c1 与 c2。\<close>

definition c1 :: "i\<Rightarrow>i" where "c1 \<equiv> \<lambda>i. 1"
definition c2 :: "i\<Rightarrow>i" where "c2 \<equiv> \<lambda>i. 2"

lemma c1_closedpt: "2 \<le> k \<Longrightarrow> closedpt(c1, k)"
  unfolding closedpt_def c1_def by auto

lemma c2_closedpt: "succ(2) \<le> k \<Longrightarrow> closedpt(c2, k)"
  unfolding closedpt_def c2_def by auto

text \<open>c2 在 k=2 处闭包失败：c2(1) = 2 不小于 2。\<close>

lemma c2_not_closed_2: "\<not> closedpt(c2, 2)"
proof -
  have "c2(1) = 2" unfolding c2_def by simp
  moreover have "1 < 2" by simp
  ultimately show ?thesis unfolding closedpt_def by force
qed

text \<open>见证分离：同一 k=2 对 c1 成立、对 c2 失败——
「每个函数都有足够强见证」的全称量词要求见证随函数变化。\<close>

corollary witnesses_depend:
  "closedpt(c1, 2) \<and> \<not> closedpt(c2, 2)"
proof
  show "closedpt(c1, 2)" by (rule c1_closedpt) simp
next
  show "\<not> closedpt(c2, 2)" by (rule c2_not_closed_2)
qed

end
