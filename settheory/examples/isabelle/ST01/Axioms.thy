theory Axioms
  imports "ZF-Constructible.Formula" "ZF.CardinalArith"
begin

text \<open>
第 01 章 公理：ZF 内核里的九条公理。

Isabelle/ZF 把公理做进 object-logic（ZF_Base.thy 的 axiomatization）。
本章逐条展示公理原貌，并用它们做第一件实事：从配对构造单点集、
验证配对的对称性。
\<close>

section \<open>公理原貌\<close>

text \<open>外延公理（集合由元素决定）：\<close>
thm extension

text \<open>并公理（u 属于 \<Union>(C) 当且仅当 u 属于 C 的某成员）：\<close>
thm Union_iff

text \<open>幂集公理（Pow(B) 的成员恰是 B 的子集）：\<close>
thm Pow_iff

text \<open>无穷公理（存在归纳集 Inf）：\<close>
thm infinity

text \<open>正则公理（每个非空集有 \<in>-极小元）：\<close>
thm foundation

text \<open>替换公理模式（函数像限制在集合上是集合）：\<close>
thm replacement

section \<open>用公理干活\<close>

text \<open>配对的存在性与唯一性在 ZF 库中已可用；
upair_def 给出 {a,b} 的成员刻画：\<close>
thm Upair_iff

text \<open>单点集 {a} 定义为 Upair a a（singleton_def）：\<close>
thm singleton_iff

text \<open>第一件实事：配对是对称的——{a,b} = {b,a}。\<close>
lemma pair_commute: "Upair(a, b) = Upair(b, a)"
proof -
  have "Upair(a,b) \<subseteq> Upair(b,a)"
    by (auto simp: Upair_iff)
  moreover
  have "Upair(b,a) \<subseteq> Upair(a,b)"
    by (auto simp: Upair_iff)
  ultimately
  show ?thesis
    by (rule equalityI)
qed

text \<open>证明用的正是外延公理（equalityI 即 extension 的两向使用）。\<close>

text \<open>Kuratowski 有序对 (a,b) = {{a},{a,b}}（ordpair_def 或手写）：\<close>
definition OPair :: "[i,i] \<Rightarrow> i" where
  "OPair(a,b) \<equiv> {{a}, {a,b}}"

text \<open>有序对刻画（Jech (1.1)）：相等当且仅当分量相等。
这里给出 (a,b) = (c,d) 蕴含 a = c 的半边；另一边对称。\<close>
lemma opair_injective_first:
  assumes h: "OPair(a,b) = OPair(c,d)"
  shows "a = c"
proof (rule ccontr)
  assume "a \<noteq> c"
  have step1: "{a} \<in> {{a}, {a,b}}"
    by (simp add: Upair_iff)
  have step2: "{a} \<in> {{c}, {c,d}}"
    using step1 h unfolding OPair_def by simp
  then have disj: "{a} = {c} \<or> {a} = {c,d}"
    by (auto simp: Upair_iff)
  then show False
  proof (elim disjE)
    assume "{a} = {c}"
    then have "a = c" by blast
    with \<open>a \<noteq> c\<close> show False by contradiction
  next
    assume "{a} = {c,d}"
    then have "c \<in> {a}" by (auto simp: Upair_iff)
    then have "a = c" by blast
    with \<open>a \<noteq> c\<close> show False by contradiction
  qed
qed

end
