theory Supercompact
  imports "ZF.Nat"
begin

text \<open>第 100 章：有限 P_\<kappa>(\<lambda>) 的精细锥与 Fodor 回归影子。
超紧本体（正规精细测度、(\<kappa>,\<lambda>)-超紧嵌入的一致性）留在正文。\<close>

definition N3 :: "i" where "N3 \<equiv> succ(succ(succ(0)))"

(* 精细锥：固定小集 s 的上锥 {t \<in> Pow(N3) : s \<subseteq> t}。 *)
definition cone :: "i => i" where
  "cone(s) \<equiv> {t \<in> Pow(N3). s \<subseteq> t}"

lemma cone_full: "cone(0) = Pow(N3)"
  by (auto simp add: cone_def)

lemma cone_inter_union: "cone(s \<union> u) = cone(s) \<inter> cone(u)"
  by (auto simp add: cone_def)

lemma cone_mono: "s \<subseteq> u \<Longrightarrow> cone(u) \<subseteq> cone(s)"
  by (auto simp add: cone_def)

lemma cone_nonempty: "s \<subseteq> N3 \<Longrightarrow> cone(s) \<noteq> 0"
  by (auto simp add: cone_def)

(* 主超滤对别人的锥不精良：含 c 的一切子集不含 d-锥（d\<noteq>c）。
   有限 P(\<kappa>) 上没有精良超滤子。 *)
definition principal :: "i => i" where
  "principal(c) \<equiv> {t \<in> Pow(N3). c \<in> t}"

lemma principal_misses_cone:
  "c \<in> N3 \<Longrightarrow> c \<noteq> succ(succ(0)) \<Longrightarrow>
   {succ(succ(0))} \<notin> principal(c)"
  by (auto simp add: principal_def)

end
