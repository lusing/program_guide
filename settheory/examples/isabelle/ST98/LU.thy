theory LU
  imports "ZF-Constructible.AC_in_L"
begin

text \<open>第 98 章：可测基数内模型 L[U] 的锚点与谓词截断影子。
L 层级的官方方程（Lset_0/Lset_succ/Lset_Union）与 DPow 的
绝对不变性（构造层级只依赖谓词外延）。\<close>

section \<open>L 层级官方锚点（第二卷定理 II.2.17 的地基）\<close>

thm Lset_0 Lset_succ Lset_Union

text \<open>DPow 是带参数可定义子集之全体（DPow_subset_Pow 即
𝒟(M) ⊆ P(M)）。L[U] 层级与之平行：
L_0[U]=0、L_{succ(i)}[U]=DPow(L_i[U], U∩L_i[U])。谓词截断
U∩L_i[U] 由引理 II.2.24 保证收敛到 U∩L[U]。\<close>

thm DPow_subset_Pow

section \<open>谓词外延性影子：外延相等的谓词给出相同定义内容\<close>

definition Pext :: "i => i => o" where
  "Pext(X, Y) \<equiv> (\<forall>n. n \<in> X \<longleftrightarrow> n \<in> Y)"

lemma Pext_refl: "Pext(X, X)" by (simp add: Pext_def)

lemma Pext_sym: "Pext(X, Y) \<Longrightarrow> Pext(Y, X)"
  by (simp add: Pext_def)

lemma Pext_trans: "Pext(X, Y) \<Longrightarrow> Pext(Y, Z) \<Longrightarrow> Pext(X, Z)"
  by (auto simp add: Pext_def)

section \<open>截断不变量：谓词段截断的基本事实\<close>

definition seg :: "i => i => i" where
  "seg(X, k) \<equiv> X \<inter> k"

lemma seg_subset: "seg(X, k) \<subseteq> X" by (auto simp add: seg_def)

lemma seg_mono: "k \<subseteq> l \<Longrightarrow> seg(seg(X, k), l) = seg(X, k)"
  unfolding seg_def by (simp add: Int_assoc Int_absorb2)

lemma seg_union: "seg(X, k \<union> l) = seg(X, k) \<union> seg(X, l)"
  unfolding seg_def by (simp only: Int_Un_distrib)

end
