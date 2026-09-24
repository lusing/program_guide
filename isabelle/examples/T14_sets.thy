theory T14_sets
  imports Main
begin

section \<open>14.1 集合：HOL 里的"谓词即集合"\<close>

text \<open>HOL 里 @{verbatim "'a set"} 就是 @{verbatim "'a ⇒ bool"} 的马甲：
集合是有类型的，元素是同类型的项。本章过一遍集合语言
与自动方法的分工。\<close>

ML \<open>writeln "==== 14 开始 ===="\<close>

subsection \<open>14.2 记法与求值\<close>

value "{1::nat, 2, 3}"
value "{1::nat, 2} \<union> {2, 3}"
value "{1::nat, 2} \<inter> {2, 3}"
value "{1::nat, 2} - {2}"
value "(\<lambda>n::nat. n + 1) ` {1, 2}"
value "insert (1::nat) {2, 3}"

text \<open>注意 @{verbatim "{n::nat. n < 3}"}（集合推导）不能求值：
它是个谓词，没有"元素列表"形式，求值器会直接报
@{verbatim "Type nat not of sort enum"}。
求值器只认有限枚举式集合；量化的集合性质交给 @{verbatim "blast"}。\<close>

subsection \<open>14.3 集合等式的标准证明法\<close>

lemma set_ext_demo: "{n::nat. n < 3} = {0, 1, 2}"
  by auto

lemma union_assoc_demo: "A \<union> (B \<union> C) = (A \<union> B) \<union> C"
  by blast

lemma inter_union_demo: "A \<inter> (B \<union> C) = (A \<inter> B) \<union> (A \<inter> C)"
  by blast

lemma diff_demo: "A - B = {x. x \<in> A \<and> x \<notin> B}"
  by blast

subsection \<open>14.4 元素级推理：auto 的标准套路\<close>

text \<open>集合等式/包含的标准套路是"元素化"：
把 @{verbatim "A ⊆ B"} 展开成 @{verbatim "∀x. x ∈ A ⟶ x ∈ B"}。
@{verbatim "by auto"} 会自动做这一步。\<close>

lemma subset_demo: "A \<subseteq> B \<Longrightarrow> B \<subseteq> C \<Longrightarrow> A \<subseteq> C"
  by blast

lemma image_demo: "f ` (A \<union> B) = f ` A \<union> f ` B"
  by blast

lemma image_inter_demo: "f ` (A \<inter> B) \<subseteq> f ` A \<inter> f ` B"
  by blast

subsection \<open>14.5 有限集合与折叠\<close>

value "foldr (+) [1::nat, 2, 3] 0"
value "Max {1::nat, 5, 3}"
value "card {1::nat, 2, 3}"

lemma card_insert_demo: "finite A \<Longrightarrow> x \<notin> A \<Longrightarrow> card (insert x A) = Suc (card A)"
  by simp

subsection \<open>14.6 有界量化与并集\<close>

lemma UN_demo: "(\<Union>i::nat. {i}) = UNIV"
  by blast

lemma bounded_demo: "(\<forall>x \<in> {1::nat, 2}. x > 0)"
  by auto

ML \<open>writeln "==== 14 结束 ===="\<close>

end
