theory PerfectConnected
  imports "HOL-Analysis.Analysis"
begin

(* 第 13 章 完备集与连通集：Isabelle 通道。
   闭区间不可数、半开区间的分离、直线上连通等价于区间、带缺口的并集不连通。 *)

lemma open_unit_uncountable:
  "uncountable {0<..<1::real}"
  by (simp add: uncountable_open_interval)

lemma neg_countable_false:
  assumes "\<not> countable (A :: real set)" and "countable A"
  shows False
  using assms by (rule notE)

lemma closed_unit_uncountable:
  "uncountable {0..1::real}"
proof -
  have sub: "{0<..<1::real} \<subseteq> {0..1}"
  proof
    fix x
    assume "x \<in> {0<..<1::real}"
    then have "0 < x" and "x < 1" by simp_all
    then have "0 \<le> x \<and> x \<le> 1" by simp
    then show "x \<in> {0..1}" by simp
  qed
  show "uncountable {0..1::real}"
  proof (rule ccontr)
    assume "\<not> uncountable {0..1::real}"
    then have "countable {0..1::real}" by simp
    from sub this have cnt: "countable {0<..<1::real}" by (rule countable_subset)
    have unc: "uncountable {0<..<1::real}" by (rule open_unit_uncountable)
    from unc have neg: "\<not> countable {0<..<1::real}" by simp
    show False by (rule neg_countable_false[OF neg cnt])
  qed
qed

lemma closure_right_half:
  "closure {0<..3::real} = {0..3}"
  by (rule closure_greaterThanAtMost) simp

lemma closure_left_half:
  "closure {-3..<0::real} = {-3..0}"
  by (rule closure_atLeastLessThan) simp

lemma left_open_cap_right_closed:
  "{-3..<0::real} \<inter> {0..3} = {}"
proof (rule equalityI)
  show "{} \<subseteq> {-3..<0::real} \<inter> {0..3}" by simp
  show "{-3..<0::real} \<inter> {0..3} \<subseteq> {}"
  proof
    fix x
    assume xin: "x \<in> {-3..<0::real} \<inter> {0..3}"
    then have xl: "x < 0" and xr: "0 \<le> x" by simp_all
    from xl xr have "x < x" by (rule less_le_trans)
    then show "x \<in> {}" by simp
  qed
qed

lemma left_closed_cap_right_open:
  "{-3..0::real} \<inter> {0<..3} = {}"
proof (rule equalityI)
  show "{} \<subseteq> {-3..0::real} \<inter> {0<..3}" by simp
  show "{-3..0::real} \<inter> {0<..3} \<subseteq> {}"
  proof
    fix x
    assume xin: "x \<in> {-3..0::real} \<inter> {0<..3}"
    then have xl: "x \<le> 0" and xr: "0 < x" by simp_all
    from xl xr have "x < x" by (rule le_less_trans)
    then show "x \<in> {}" by simp
  qed
qed

lemma halves_separated:
  "{-3..<0::real} \<inter> closure {0<..3} = {} \<and>
   closure {-3..<0::real} \<inter> {0<..3} = {}"
proof
  have eq1: "{-3..<0::real} \<inter> closure {0<..3} = {-3..<0} \<inter> {0..3}"
    by (simp only: closure_right_half)
  show "{-3..<0::real} \<inter> closure {0<..3} = {}"
    by (simp only: eq1 left_open_cap_right_closed)
next
  have eq2: "closure {-3..<0::real} \<inter> {0<..3} = {-3..0} \<inter> {0<..3}"
    by (simp only: closure_left_half)
  show "closure {-3..<0::real} \<inter> {0<..3} = {}"
    by (simp only: eq2 left_closed_cap_right_open)
qed

lemma touching_disjoint:
  "{-3..0::real} \<inter> {0<..3} = {}"
  by (rule left_closed_cap_right_open)

lemma touching_meets_closure:
  "0 \<in> {-3..0::real} \<inter> closure {0<..3}"
proof -
  have left: "0 \<in> {-3..0::real}" by simp
  have "0 \<in> {0..3::real}" by simp
  then have right: "0 \<in> closure {0<..3::real}" by (simp only: closure_right_half)
  from left right show ?thesis by simp
qed

lemma separated_subset:
  fixes A B A1 B1 :: "real set"
  assumes hAB: "A \<inter> closure B = {}"
    and hBA: "closure A \<inter> B = {}"
    and hA: "A1 \<subseteq> A"
    and hB: "B1 \<subseteq> B"
  shows "A1 \<inter> closure B1 = {}"
proof -
  have monoB: "closure B1 \<subseteq> closure B" using hB by (rule closure_mono)
  have "A1 \<inter> closure B1 \<subseteq> A \<inter> closure B"
  proof
    fix x
    assume xin: "x \<in> A1 \<inter> closure B1"
    then have xA1: "x \<in> A1" and xB1: "x \<in> closure B1" by simp_all
    from hA xA1 have "x \<in> A" by (rule subsetD)
    from monoB xB1 have "x \<in> closure B" by (rule subsetD)
    then show "x \<in> A \<inter> closure B" using \<open>x \<in> A\<close> by simp
  qed
  then have "A1 \<inter> closure B1 \<subseteq> {}" by (simp only: hAB)
  then show ?thesis by simp
qed

lemma empty_is_connected:
  "connected ({} :: real set)"
  by simp

lemma closed_unit_connected:
  "connected {0..1::real}"
  by (rule connected_interval)

lemma open_unit_between:
  fixes a b x :: real
  assumes aS: "a \<in> {0<..<1}" and bS: "b \<in> {0<..<1}"
    and ax: "a \<le> x" and xb: "x \<le> b"
  shows "x \<in> {0<..<1}"
proof -
  from aS have a0: "0 < a" by simp
  from bS have b1: "b < 1" by simp
  from a0 ax have "0 < x" by (rule less_le_trans)
  from xb b1 have "x < 1" by (rule le_less_trans)
  then show "x \<in> {0<..<1}" using \<open>0 < x\<close> by simp
qed

lemma open_unit_is_interval:
  "is_interval {0<..<1::real}"
  unfolding is_interval_1
proof (intro ballI allI impI)
  fix a b x :: real
  assume aS: "a \<in> {0<..<1}" and bS: "b \<in> {0<..<1}" and axb: "a \<le> x \<and> x \<le> b"
  from axb have ax: "a \<le> x" and xb: "x \<le> b" by simp_all
  from aS bS ax xb show "x \<in> {0<..<1}" by (rule open_unit_between)
qed

lemma open_unit_connected:
  "connected {0<..<1::real}"
proof -
  have "is_interval {0<..<1::real}" by (rule open_unit_is_interval)
  then show ?thesis by (rule is_interval_connected_1[THEN iffD1])
qed

lemma zero_between_bounds: "-1 \<le> (0::real) \<and> (0::real) \<le> (1::real)"
proof (rule conjI)
  show "-1 \<le> (0::real)" by simp
  show "(0::real) \<le> (1::real)" by (rule zero_le_one)
qed

lemma gap_not_interval:
  "\<not> is_interval ({-3..<0::real} \<union> {0<..3})"
proof
  assume iv: "is_interval ({-3..<0::real} \<union> {0<..3})"
  from iv have ball: "\<forall>a\<in>{-3..<0::real} \<union> {0<..3}. \<forall>b\<in>{-3..<0::real} \<union> {0<..3}.
      \<forall>x. a \<le> x \<and> x \<le> b \<longrightarrow> x \<in> {-3..<0::real} \<union> {0<..3}"
    by (rule is_interval_1[THEN iffD1])
  have a: "-1 \<in> {-3..<0::real} \<union> {0<..3}" by simp
  have b: "1 \<in> {-3..<0::real} \<union> {0<..3}" by simp
  from ball a have step1:
    "\<forall>b\<in>{-3..<0::real} \<union> {0<..3}. \<forall>x. -1 \<le> x \<and> x \<le> b \<longrightarrow>
      x \<in> {-3..<0::real} \<union> {0<..3}"
    by (rule bspec)
  from step1 b have step2:
    "\<forall>x. -1 \<le> x \<and> x \<le> (1::real) \<longrightarrow> x \<in> {-3..<0::real} \<union> {0<..3}"
    by (rule bspec)
  from step2 have impl:
    "(-1 \<le> (0::real) \<and> (0::real) \<le> (1::real)) \<longrightarrow>
      (0::real) \<in> {-3..<0::real} \<union> {0<..3}"
    by (rule spec)
  have mem: "0 \<in> {-3..<0::real} \<union> {0<..3}"
    by (rule mp[OF impl zero_between_bounds])
  from mem show False
  proof (elim UnE)
    assume "0 \<in> {-3..<0::real}"
    then show False by simp
  next
    assume "0 \<in> {0<..3::real}"
    then show False by simp
  qed
qed

lemma gap_not_connected:
  "\<not> connected ({-3..<0::real} \<union> {0<..3})"
proof
  assume conn: "connected ({-3..<0::real} \<union> {0<..3})"
  have iv: "is_interval ({-3..<0::real} \<union> {0<..3})"
    by (rule is_interval_connected_1[THEN iffD2, OF conn])
  show False by (rule notE[OF gap_not_interval iv])
qed

end
