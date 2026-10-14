theory Sets
  imports "ZF.EquivClass" "ZF.equalities"
begin

text \<open>第 56 章：朴素集合的代数（Makinson Ch1）。外延、包含链、
交并差定律、广义 De Morgan 与幂集。\<close>

subsection \<open>包含与外延\<close>

lemma incl_trans_example:
  assumes "A \<subseteq> B" "B \<subseteq> C" shows "A \<subseteq> C"
  using assms by (rule subset_trans)

lemma incl_cycle:
  assumes "A \<subseteq> B" "B \<subseteq> A" shows "A = B"
  using assms by (rule equalityI)

text \<open>Exercise 1.2.2 (4)(g)：A \<subseteq> B 且 B 真含于 C 推出 A 真含于 C。
  真包含没有记号，用"包含 + 见证元素"表达。\<close>

lemma proper_incl_trans:
  assumes "A \<subseteq> B" "B \<subseteq> C" "x \<in> C" "x \<notin> B"
  shows "A \<subseteq> C" "x \<notin> A"
proof -
  show "A \<subseteq> C" using assms(1,2) by (rule subset_trans)
  show "x \<notin> A" using assms(1,3,4) by blast
qed

subsection \<open>交并差的代数\<close>

lemma dist_meet_over_uni: "A \<inter> (B \<union> C) = (A \<inter> B) \<union> (A \<inter> C)"
  by (rule Int_Un_distrib)

lemma dist_uni_over_meet: "A \<union> (B \<inter> C) = (A \<union> B) \<inter> (A \<union> C)"
  by blast

lemma demorgan_diff: "A - (B \<union> C) = (A - B) \<inter> (A - C)"
  by (rule Diff_Un)

lemma demorgan_diff2: "A - (B \<inter> C) = (A - B) \<union> (A - C)"
  by blast

subsection \<open>广义 De Morgan：非空索引族上的关键一步\<close>

text \<open>INT_iff 把 A\<noteq>0 打包进成员刻画——空族的交会退化，
  这是 Makinson 1.5 节习题 (c)(d) 的隐藏前提，机器把它显式化了。\<close>

lemma gen_demorgan:
  assumes neC: "C \<noteq> 0"
  shows "U - (\<Union>x\<in>C. f(x)) = (\<Inter>x\<in>C. U - f(x))"
proof (rule equalityI)
  show "U - (\<Union>x\<in>C. f(x)) \<subseteq> (\<Inter>x\<in>C. U - f(x))"
  proof (rule subsetI)
    fix y assume hy: "y \<in> U - (\<Union>x\<in>C. f(x))"
    hence hU: "y \<in> U" and hn: "y \<notin> (\<Union>x\<in>C. f(x))" by blast+
    show "y \<in> (\<Inter>x\<in>C. U - f(x))"
      using neC hU hn by (blast intro: INT_I)
  qed
next
  show "(\<Inter>x\<in>C. U - f(x)) \<subseteq> U - (\<Union>x\<in>C. f(x))"
  proof (rule subsetI)
    fix y assume hy: "y \<in> (\<Inter>x\<in>C. U - f(x))"
    from neC obtain x0 where "x0 \<in> C" by (rule not_emptyE) blast
    hence hy0: "y \<in> U - f(x0)" using hy by (blast dest: INT_E)
    thus "y \<in> U - (\<Union>x\<in>C. f(x))" using hy by (blast dest: INT_E)
  qed
qed

subsection \<open>幂集：\$P(\{0,1\})\$ 恰有四个元素\<close>

lemma Pow_two: "Pow({0,1}) = {0, {0}, {1}, {0,1}}"
proof (rule equalityI)
  show "{0,{0},{1},{0,1}} \<subseteq> Pow({0,1})" by blast
next
  show "Pow({0,1}) \<subseteq> {0,{0},{1},{0,1}}"
  proof (rule subsetI)
    fix X assume "X \<in> Pow({0,1})"
    hence hX: "X \<subseteq> {0,1}" by (rule PowD)
    show "X \<in> {0,{0},{1},{0,1}}"
    proof (cases "0 \<in> X"; cases "1 \<in> X")
      assume h0: "0 \<in> X" and h1: "1 \<in> X"
      hence "X = {0,1}" using hX by (blast intro: equalityI)
      thus ?thesis by (simp only: cons_iff; blast)
    next
      assume h0: "0 \<in> X" and h1: "1 \<notin> X"
      hence "X = {0}" using hX by (blast intro: equalityI)
      thus ?thesis by (simp only: cons_iff; blast)
    next
      assume h0: "0 \<notin> X" and h1: "1 \<in> X"
      hence "X = {1}" using hX by (blast intro: equalityI)
      thus ?thesis by (simp only: cons_iff; blast)
    next
      assume h0: "0 \<notin> X" and h1: "1 \<notin> X"
      hence "X = 0" using hX by (blast intro: equalityI)
      thus ?thesis by (simp only: cons_iff; blast)
    qed
  qed
qed

end
