theory Replacement
  imports "ZF"
begin

text \<open>第 70 章：第二递归定义定理与彻底有限集合（冯琦 §1.5-1.6）。
映像存在原理（替换公理，公理 8）的实名锚点；Vₙ 层塔（定义 1.53）。\<close>

subsection \<open>公理 8：映像存在原理（ZF_Base 的 replacement）\<close>

text \<open>ZF\_Base.thy 原文：泛函定义式的像存在（泛函条件 + 值域成集）。
导出形态 Replace（关系版）与 RepFun（函数版）。\<close>

lemma repfun_image: "b \<in> A \<Longrightarrow> f(b) \<in> {f(x) . x \<in> A}"
  by (rule RepFunI)

text \<open>第二递归定义定理（定理 1.40）的合法性引擎就是这一条：把
"定义在 n+1 上的有限近似 h" 整体搬运成集合。\<close>

subsection \<open>Vₙ 层塔（定义 1.53：V₀ = 0，Vₙ₊₁ = Pow(Vₙ)）\<close>

definition Vn :: "i \<Rightarrow> i" where
  "Vn(n) \<equiv> nat_rec(n, 0, \<lambda>m x. Pow(x))"

lemma Vn_0: "Vn(0) = 0"
  by (simp add: Vn_def nat_rec_0)

lemma Vn_succ: "n \<in> nat \<Longrightarrow> Vn(succ(n)) = Pow(Vn(n))"
  by (simp add: Vn_def nat_rec_succ)

lemma subset_0_eq: "a \<subseteq> 0 \<Longrightarrow> a = 0"
  by (rule equalityI, assumption, rule empty_subsetI)

lemma Pow_0_eq: "Pow(0) = {0}"
proof (rule equalityI)
  show "{0} \<subseteq> Pow(0)"
    by (blast intro: PowI empty_subsetI)
  show "Pow(0) \<subseteq> {0}"
    by (blast dest: PowD intro: subset_0_eq)
qed

lemma Vn_1: "Vn(1) = {0}"
  by (simp add: Vn_def nat_rec_succ nat_rec_0 Pow_0_eq)

text \<open>彻底有限集合（定义 1.54）与 V_omega = 全体 Vn(n) 之并
（定义 1.53(3)）：合法性 = RepFun（替换）+ Union（并集公理）——
两个引擎各上一条。\<close>

definition Vomega where
  "Vomega \<equiv> \<Union>({Vn(n) . n \<in> nat})"

lemma Vn_in_Vomega: "n \<in> nat \<Longrightarrow> Vn(n) \<subseteq> Vomega"
  by (auto simp: Vomega_def)

end
