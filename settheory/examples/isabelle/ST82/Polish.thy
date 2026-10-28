theory Polish
  imports "ZF.Nat"
begin

text \<open>第 82 章：闭集树表示（定理 3.26）的有限影子。深度 2 的二叉树
以节点集给出；T 是剪枝树；chain 是 T 中的完整树枝；TX 是树枝全体
的表示树（自动剪掉死节点）。\<close>

definition N3 :: "i" where "N3 \<equiv> succ(2)"
definition N4 :: "i" where "N4 \<equiv> succ(N3)"
definition N5 :: "i" where "N5 \<equiv> succ(N4)"
definition N6 :: "i" where "N6 \<equiv> succ(N5)"
definition N7 :: "i" where "N7 \<equiv> succ(N6)"

definition T :: "i" where "T \<equiv> {1, 2, N3, N4, N5}"
definition PAR :: "i" where
  "PAR \<equiv> {\<langle>1,2\<rangle>, \<langle>1,N3\<rangle>, \<langle>2,N4\<rangle>, \<langle>2,N5\<rangle>,
             \<langle>N3,N6\<rangle>, \<langle>N3,N7\<rangle>}"
definition TX :: "i" where "TX \<equiv> {1, 2, N4, N5}"
definition LEAVES :: "i" where "LEAVES \<equiv> {N4, N5, N6, N7}"

(* 前缀封闭：T 中每个非根节点的父节点也在 T 中。 *)
lemma T_prefix_closed:
  "\<forall>c \<in> T. c = 1 \<or> (\<exists>p. \<langle>p,c\<rangle> \<in> PAR \<and> p \<in> T)"
  by (auto simp add: T_def PAR_def N3_def N4_def N5_def)

(* chain(n)：n 是叶且 n 的父链两级都在 T 中（深度 2 的完整树枝）。 *)
definition chain :: "i => o" where
  "chain(n) \<equiv> n \<in> LEAVES \<and> n \<in> T \<and>
    (\<exists>p. \<langle>p,n\<rangle> \<in> PAR \<and> p \<in> T \<and> (\<exists>g. \<langle>g,p\<rangle> \<in> PAR))"

lemma chain_4: "chain(N4)"
  by (auto simp add: chain_def LEAVES_def T_def PAR_def N4_def)

lemma chain_5: "chain(N5)"
  by (auto simp add: chain_def LEAVES_def T_def PAR_def N5_def)

lemma not_chain_6: "\<not> chain(N6)"
  by (simp add: chain_def LEAVES_def T_def N3_def N4_def N5_def N6_def)

(* T 的全体树枝恰为 {N4, N5}：剪掉 6、7 后右枝只剩一个叶。 *)
lemma body_T: "{n \<in> LEAVES. chain(n)} = {N4, N5}"
  by (auto simp add: chain_def LEAVES_def T_def PAR_def
                     N3_def N4_def N5_def N6_def N7_def)

(* 表示树自动剪掉死节点 N3，且在同一叶域上重建同一树枝全体。 *)
lemma dead_3: "N3 \<in> T \<and> N3 \<notin> TX"
  by (auto simp add: T_def TX_def N3_def N4_def N5_def)

lemma TX_subset: "TX \<subseteq> T"
  by (auto simp add: TX_def T_def)

lemma body_TX:
  "{n \<in> LEAVES. n \<in> TX \<and> (\<exists>p. \<langle>p,n\<rangle> \<in> PAR \<and> p \<in> TX \<and>
      (\<exists>g. \<langle>g,p\<rangle> \<in> PAR))} = {N4, N5}"
  by (auto simp add: LEAVES_def TX_def PAR_def
                    N3_def N4_def N5_def N6_def N7_def)

end
