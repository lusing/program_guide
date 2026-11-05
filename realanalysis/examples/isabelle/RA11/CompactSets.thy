theory CompactSets
  imports "HOL-Analysis.Analysis"
begin

(* 第 11 章 紧集：Isabelle 通道。
   开覆盖的例子、有限集、开区间不紧、相对紧致、闭子集、有界、
   嵌套交、无限子集的极限点。证明用单步规则。 *)

lemma finite_subcover_sample:
  "{-3..3::real} \<subseteq> {-4<..<0} \<union> {-1<..<3} \<union> {2<..<6}"
proof
  fix x :: real
  assume xin: "x \<in> {-3..3}"
  then have lo: "-3 \<le> x" and hi: "x \<le> 3" by simp_all
  show "x \<in> {-4<..<0} \<union> {-1<..<3} \<union> {2<..<6}"
  proof (cases "x < 0")
    case True
    then have "x \<in> {-4<..<0}" using lo by simp
    then show ?thesis by simp
  next
    case False
    then have xz: "0 \<le> x" by simp
    show ?thesis
    proof (cases "x < 3")
      case True
      then have "x \<in> {-1<..<3}" using xz by simp
      then show ?thesis by simp
    next
      case False
      then have "3 \<le> x" by simp
      with hi have "x = 3" by simp
      then have "x \<in> {2<..<6}" by simp
      then show ?thesis by simp
    qed
  qed
qed

lemma empty_compact: "compact ({} :: real set)"
  by simp

lemma singleton_compact: "compact ({p} :: real set)"
  by simp

lemma finite_is_compact: "finite (K :: real set) \<Longrightarrow> compact K"
  by (rule finite_imp_compact)

lemma compact_is_closed: "compact (K :: real set) \<Longrightarrow> closed K"
  by (rule compact_imp_closed)

lemma open_interval_not_compact: "\<not> compact {0<..<1::real}"
proof
  assume c: "compact {0<..<1::real}"
  then have cl: "closed {0<..<1::real}" by (rule compact_imp_closed)
  have in1: "(1::real) \<in> closure {0<..<1}" by simp
  have eqc: "closure {0<..<1::real} = {0<..<1}"
    using cl by (simp only: closure_eq)
  have "(1::real) \<in> {0<..<1}"
    using in1 by (simp only: eqc)
  then show False by simp
qed

lemma rel_compact:
  assumes "K \<subseteq> (Y :: real set)"
  shows "compactin (top_of_set Y) K \<longleftrightarrow> compact K"
proof -
  have "compactin (top_of_set Y) K \<longleftrightarrow> compactin euclidean K \<and> K \<subseteq> Y"
    by (simp add: compactin_subtopology)
  also have "\<dots> \<longleftrightarrow> compact K \<and> K \<subseteq> Y"
    by (simp add: compactin_euclidean_iff)
  also have "\<dots> \<longleftrightarrow> compact K"
    using assms by simp
  finally show ?thesis .
qed

lemma closed_subset_of_compact:
  assumes "compact (K :: real set)" "closed F" "F \<subseteq> K"
  shows "compact F"
proof -
  have "compact (F \<inter> K)"
    using assms(2) assms(1) by (rule closed_Int_compact)
  moreover have "F \<inter> K = F"
    using assms(3) by (simp add: Int_absorb2)
  ultimately show "compact F" by simp
qed

lemma closed_inter_compact:
  assumes "compact (K :: real set)" "closed F"
  shows "compact (F \<inter> K)"
  using assms(2) assms(1) by (rule closed_Int_compact)

lemma not_subset_abuse: "\<not> ({-5..5::real} \<subseteq> {-3<..<3})"
proof
  assume sub: "{-5..5::real} \<subseteq> {-3<..<3}"
  have mem: "4 \<in> {-5..5::real}" by simp
  from sub mem have "4 \<in> {-3<..<3::real}" by (rule subsetD)
  then show False by simp
qed

lemma compact_is_bounded: "compact (K :: real set) \<Longrightarrow> bounded K"
  by (rule compact_imp_bounded)

lemma not_bounded_UNIV_real: "\<not> bounded (UNIV :: real set)"
proof
  assume b: "bounded (UNIV :: real set)"
  from b have "\<exists>a. \<forall>x\<in>UNIV. norm (x::real) \<le> a"
    by (simp add: bounded_iff)
  then obtain a where a: "\<forall>x\<in>UNIV. norm (x::real) \<le> a" by (rule exE)
  have mem: "\<bar>a\<bar> + 1 \<in> (UNIV :: real set)" by simp
  have "norm (\<bar>a\<bar> + (1::real)) \<le> a"
    using a mem by (rule bspec)
  then have "\<bar>a\<bar> + 1 \<le> a" by simp
  moreover have "a \<le> \<bar>a\<bar>" by simp
  ultimately show False by simp
qed

lemma univ_not_compact: "\<not> compact (UNIV :: real set)"
proof
  assume "compact (UNIV :: real set)"
  then have "bounded (UNIV :: real set)" by (rule compact_imp_bounded)
  then show False using not_bounded_UNIV_real by simp
qed

lemma compact_fip_real:
  "compact (U :: real set) \<longleftrightarrow>
    (\<forall>A. (\<forall>a\<in>A. closed a) \<longrightarrow>
      (\<forall>B \<subseteq> A. finite B \<longrightarrow> U \<inter> \<Inter>B \<noteq> {}) \<longrightarrow> U \<inter> \<Inter>A \<noteq> {})"
  by (rule compact_fip)

lemma nested_compact_inter:
  fixes F :: "nat \<Rightarrow> real set"
  assumes "\<And>n. compact (F n)" "\<And>n. F n \<noteq> {}" "\<And>m n. m \<le> n \<Longrightarrow> F n \<subseteq> F m"
  shows "(\<Inter>n. F n) \<noteq> {}"
  using assms by (rule compact_nest)

lemma infinite_has_limit_point:
  assumes "compact (K :: real set)" "infinite E" "E \<subseteq> K"
  shows "\<exists>x\<in>K. x islimpt E"
  using assms by (rule Heine_Borel_imp_Bolzano_Weierstrass)

end
