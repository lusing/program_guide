theory Summary
  imports "HOL-Analysis.Analysis"
begin

(* 第 20 章 总结：Isabelle 通道。
   集合相等、德摩根、阿基米德、三角不等式、把 ε 拆成两半，
   以及公比 1/2 的几何级数。 *)

lemma set_eq_iff:
  fixes A B :: "'a set"
  shows "A = B \<longleftrightarrow> A \<subseteq> B \<and> B \<subseteq> A"
proof
  assume "A = B"
  then show "A \<subseteq> B \<and> B \<subseteq> A" by simp
next
  assume "A \<subseteq> B \<and> B \<subseteq> A"
  then have "A \<subseteq> B" and "B \<subseteq> A" by simp_all
  then show "A = B" by (rule subset_antisym)
qed

lemma de_morgan:
  fixes A B :: "'a set"
  shows "- (A \<union> B) = (- A) \<inter> (- B)"
  by (rule Compl_Un)

lemma past_five: "\<exists>n::nat. (5::real) < of_nat n"
  by (rule reals_Archimedean2)

lemma triangle: "\<bar>(x::real) + y\<bar> \<le> \<bar>x\<bar> + \<bar>y\<bar>"
  by (rule abs_triangle_ineq)

lemma eps_split: "(e::real) / 2 + e / 2 = e"
  by simp

lemma geometric_is_sequence: "suminf (\<lambda>n. ((1::real) / 2) ^ n) = 2"
proof -
  have "suminf (\<lambda>n. ((1::real) / 2) ^ n) = 1 / (1 - 1 / 2)"
    by (rule suminf_geometric) simp
  then show ?thesis by simp
qed

lemma binomial_drop: "(1::real) + 2 * (1 / 2) < (3 / 2) ^ 2"
proof -
  have left: "(1::real) + 2 * (1 / 2) = 2" by simp
  have "(3 / 2 :: real) ^ 2 = (3 / 2) * (3 / 2)"
    by (rule power2_eq_square)
  also have "... = 9 / 4" by simp
  finally have right: "(3 / 2 :: real) ^ 2 = 9 / 4" .
  show ?thesis by (simp add: left right)
qed

end
