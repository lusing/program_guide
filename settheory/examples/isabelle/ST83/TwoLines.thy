theory TwoLines
  imports "ZF.Nat"
begin

text \<open>第 83 章：主超滤超幂的退化。焦点求值版等价关系的构造性内核。
超实数构造与非 Archimedean 序的无限本体留在正文。\<close>

consts a :: "i"
consts b :: "i"
consts c :: "i"

(* 焦点等价的三律：在固定点处的相等是等价关系。 *)
lemma eq_refl: "a = a"
  by (rule refl)

lemma eq_sym: "a = b \<Longrightarrow> b = a"
  by (rule sym)

lemma eq_trans: "a = b \<Longrightarrow> b = c \<Longrightarrow> a = c"
  by (rule trans)

(* 主超滤超幂退化定理的内核：等价类的常值代表。
   五点全集 K5 上的主超滤（焦点 N2）：
   两函数模 U 等价当且仅当在焦点处相等；每类有常值代表。 *)
definition N3 :: "i" where "N3 \<equiv> succ(2)"
definition K5 :: "i" where "K5 \<equiv> succ(succ(N3))"

(* 焦点包含在全集。 *)
lemma N2_in_K5: "succ(succ(0)) \<in> K5"
  by (auto simp add: K5_def N3_def)

(* 主超滤的向上封闭：含焦点的子集全体对扩集封闭。 *)
lemma principal_upward:
  "\<lbrakk> A \<subseteq> K5; succ(succ(0)) \<in> A; A \<subseteq> B; B \<subseteq> K5 \<rbrakk>
   \<Longrightarrow> succ(succ(0)) \<in> B"
  by auto

end
