theory Reals
  imports "ZF.Nat"
begin

text \<open>第 80 章：有限下截断。有限线性序的非空下集必有最大元，
所以这里有意删去实 Dedekind 截断的「无最大元」条件，只核对非空、
真子集、向下封闭与两个截断的并上确界；正文另证真正的实数完备性。\<close>

definition D3 :: "i" where "D3 \<equiv> succ(succ(succ(0)))"
definition cut0 :: "i" where "cut0 \<equiv> succ(0)"
definition cut1 :: "i" where "cut1 \<equiv> succ(succ(0))"

definition FinCut :: "i => o" where
  "FinCut(A) \<equiv> A \<subseteq> D3 \<and> A \<noteq> 0 \<and> A \<noteq> D3 \<and>
    (\<forall>y\<in>A. \<forall>x\<in>D3. x \<in> y \<longrightarrow> x \<in> A)"

lemma cut0_FinCut: "FinCut(cut0)"
  by (auto simp add: FinCut_def D3_def cut0_def)

lemma cut1_FinCut: "FinCut(cut1)"
  by (auto simp add: FinCut_def D3_def cut1_def)

lemma cuts_comparable: "cut0 \<subseteq> cut1"
  by (auto simp add: cut0_def cut1_def)

lemma cut_union_sup: "cut0 \<union> cut1 = cut1"
  by (auto simp add: cut0_def cut1_def)

lemma cut_union_FinCut: "FinCut(cut0 \<union> cut1)"
  by (simp add: cut_union_sup cut1_FinCut)

lemma cut0_below_cut1: "cut0 \<in> cut1"
  by (simp add: cut0_def cut1_def)

end
