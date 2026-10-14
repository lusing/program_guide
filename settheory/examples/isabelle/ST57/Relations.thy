theory Relations
  imports "ZF.EquivClass"
begin

text \<open>第 57 章：关系的代数与等价-划分对应（Makinson Ch2）。\<close>

subsection \<open>复合的代数\<close>

lemma comp_union_distr: "(S \<union> R) O T = (S O T) \<union> (R O T)"
proof (rule equalityI)
  show "(S \<union> R) O T \<subseteq> (S O T) \<union> (R O T)"
    by blast
next
  show "(S O T) \<union> (R O T) \<subseteq> (S \<union> R) O T"
    by blast
qed

lemma converse_comp_swap: "converse(S O R) = converse(R) O converse(S)"
  by (rule converse_comp)

lemma comp_assoc_example: "(r O s) O t = r O (s O t)"
  by (rule comp_assoc)

text \<open>闭包与逆交换：自反传递版 rtrancl_converse 官方件；
  传递版 trancl_converse 取其对称形态。\<close>

lemma rtrancl_conv: "converse(r)^* = converse(r^*)"
  by (rule rtrancl_converse)

lemma trancl_conv: "converse(r^+) = (converse(r))^+"
  by (rule sym [OF trancl_converse])

subsection \<open>等价关系与商集：官方锚点\<close>

definition parityR :: i where
  "parityR \<equiv> {\<langle>0,0\<rangle>, \<langle>1,1\<rangle>, \<langle>2,2\<rangle>, \<langle>1,2\<rangle>, \<langle>2,1\<rangle>}"

lemma parity_equiv: "equiv({0,1,2}, parityR)"
  unfolding parityR_def equiv_def refl_def sym_def trans_def by blast

text \<open>划分三条件的两个直接由官方件承载：非空+穷尽 = Union_quotient。\<close>

lemma quotient_exhausts: "equiv(A,r) \<Longrightarrow> \<Union>(A//r) = A"
  by (rule Union_quotient)

lemma parity_classes:
  "parityR``{0} = {0}" "parityR``{1} = {1,2}" "parityR``{2} = {1,2}"
  unfolding parityR_def by blast+

text \<open>等价类的重合：官方件 equiv_class_eq（同类 iff 相关的 \<Rightarrow> 半边）。
  两两不交由它间接承载：类不等则不相交。\<close>

lemma parity_12_same: "parityR``{1} = parityR``{2}"
proof (rule equiv_class_eq [OF parity_equiv])
  show "\<langle>1,2\<rangle> \<in> parityR" unfolding parityR_def by blast
qed

lemma parity_classes_disjoint: "parityR``{0} \<inter> parityR``{1} = 0"
  unfolding parityR_def by blast

end
