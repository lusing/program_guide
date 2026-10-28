theory Strongcompact
  imports "ZF.Nat"
begin

text \<open>第 99 章：强紧基数的有限影子。滤子扩展骨架（层间包含）
与有限理论可满足性样本。强紧性本体（任意 X 上的 κ-完全滤子扩展
成 κ-完全超滤子）是无限命题，留在正文。\<close>

section \<open>滤基扩展骨架：三层与两层滤基\<close>

definition N3 :: "i" where "N3 \<equiv> succ(succ(succ(0)))"
definition U4 :: "i" where "U4 \<equiv> succ(N3)"

(* ≥3 层滤基：含固定三元集 {0,1,2} = N3 的子集全体。 *)
definition F3 :: "i" where
  "F3 \<equiv> {A \<in> Pow(U4). N3 \<subseteq> A}"

(* ≥2 层滤基：含 {0,1} = succ(succ(0)) 的子集全体。 *)
definition F2 :: "i" where
  "F2 \<equiv> {A \<in> Pow(U4). succ(succ(0)) \<subseteq> A}"

lemma F3_subset_F2: "F3 \<subseteq> F2"
  by (auto simp add: F3_def F2_def N3_def)

lemma F3_mem_sample: "U4 \<in> F3"
  by (auto simp add: F3_def U4_def N3_def)

lemma F2_upward: "A \<in> F2 \<Longrightarrow> A \<subseteq> B \<Longrightarrow> B \<subseteq> U4 \<Longrightarrow> B \<in> F2"
  by (auto simp add: F2_def)

lemma F3_inter_in_F2: "A \<in> F3 \<Longrightarrow> B \<in> F3 \<Longrightarrow> A \<inter> B \<in> F2"
  by (auto simp add: F3_def F2_def N3_def)

end
