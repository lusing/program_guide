theory HeineBorel
  imports "HOL-Analysis.Analysis"
begin

(* 第 12 章 海涅–博雷尔定理：Isabelle 通道。
   闭区间套用上确界，不用紧性。海涅–博雷尔与魏尔斯特拉斯用库里的等价。
   证明只用单步规则。 *)

lemma nested_closed_intervals:
  fixes a b :: "nat \<Rightarrow> real"
  assumes hab: "\<And>n. a n \<le> b n"
    and ha: "\<And>m n. m \<le> n \<Longrightarrow> a m \<le> a n"
    and hb: "\<And>m n. m \<le> n \<Longrightarrow> b n \<le> b m"
  shows "(\<Inter>n. {a n .. b n}) \<noteq> {}"
proof -
  have ne: "range a \<noteq> {}" by simp
  have bd: "bdd_above (range a)"
  proof (rule bdd_aboveI)
    fix y
    assume "y \<in> range a"
    then obtain n where yn: "y = a n" by (rule rangeE)
    have "a n \<le> b n" by (rule hab)
    also have "b n \<le> b 0"
    proof (rule hb)
      show "(0::nat) \<le> n" by simp
    qed
    finally have "a n \<le> b 0" .
    then show "y \<le> b 0" using yn by simp
  qed
  define x where "x = Sup (range a)"
  have xin: "\<And>n. x \<in> {a n .. b n}"
  proof -
    fix n
    have an_mem: "a n \<in> range a" by simp
    have an_le: "a n \<le> x"
    proof -
      have "a n \<le> Sup (range a)" by (rule cSup_upper[OF an_mem bd])
      then show ?thesis unfolding x_def by simp
    qed
    have x_le: "x \<le> b n"
    proof -
      have "Sup (range a) \<le> b n"
      proof (rule cSup_least[OF ne])
        fix y
        assume "y \<in> range a"
        then obtain m where ym: "y = a m" by (rule rangeE)
        have "a m \<le> b n"
        proof (cases "m \<le> n")
          case True
          have "a m \<le> a n" by (rule ha[OF True])
          also have "a n \<le> b n" by (rule hab)
          finally show ?thesis .
        next
          case False
          from False have "n < m" by (rule not_le_imp_less)
          then have nm: "n \<le> m" by (rule less_imp_le)
          have "a m \<le> b m" by (rule hab)
          also have "b m \<le> b n" by (rule hb[OF nm])
          finally show ?thesis .
        qed
        then show "y \<le> b n" using ym by simp
      qed
      then show ?thesis unfolding x_def by simp
    qed
    from an_le x_le show "x \<in> {a n .. b n}" by simp
  qed
  show "(\<Inter>n. {a n .. b n}) \<noteq> {}"
  proof
    assume empty: "(\<Inter>n. {a n .. b n}) = {}"
    have "x \<in> (\<Inter>n. {a n .. b n})"
    proof (rule INT_I)
      fix n
      show "x \<in> {a n .. b n}" by (rule xin)
    qed
    then have "x \<in> {}" by (simp only: empty)
    then show False by simp
  qed
qed

lemma closed_interval_compact:
  fixes a b :: real
  shows "compact {a .. b}"
  by (rule compact_interval)

lemma square_compact:
  "compact ({0 .. 1::real} \<times> {0 .. 1::real})"
proof (rule compact_Times)
  show "compact {0 .. 1::real}" by (rule compact_interval)
  show "compact {0 .. 1::real}" by (rule compact_interval)
qed

lemma bounded_in_cell:
  fixes E :: "real set"
  assumes bd: "bounded E"
  obtains M where "E \<subseteq> {-M .. M}"
proof -
  from bd have "\<exists>a. \<forall>x\<in>E. norm x \<le> a" by (simp add: bounded_iff)
  then obtain a where aE: "\<forall>x\<in>E. norm x \<le> a" by (rule exE)
  define M where "M = max a 0"
  have sub: "E \<subseteq> {-M .. M}"
  proof
    fix x
    assume xin: "x \<in> E"
    from aE xin have nx: "norm x \<le> a" by (rule bspec)
    then have ax: "\<bar>x\<bar> \<le> a" by simp
    have aM: "a \<le> M" unfolding M_def by simp
    from ax aM have "\<bar>x\<bar> \<le> M" by (rule order_trans)
    then have "- M \<le> x \<and> x \<le> M" by (simp add: abs_le_iff)
    then show "x \<in> {-M .. M}" by simp
  qed
  from sub show ?thesis by (rule that)
qed

lemma heine_borel:
  fixes E :: "real set"
  shows "compact E \<longleftrightarrow> bounded E \<and> closed E"
  by (rule compact_eq_bounded_closed)

lemma open_unit_bounded_not_compact:
  "bounded {0<..<1::real} \<and> \<not> compact {0<..<1::real}"
proof
  have sub: "{0<..<1::real} \<subseteq> {0 .. 1}"
  proof
    fix x
    assume "x \<in> {0<..<1::real}"
    then have "0 < x" and "x < 1" by simp_all
    then have "0 \<le> x \<and> x \<le> 1" by simp
    then show "x \<in> {0 .. 1}" by simp
  qed
  have "compact {0 .. 1::real}" by (rule compact_interval)
  then have "bounded {0 .. 1::real}" by (rule compact_imp_bounded)
  from this sub show "bounded {0<..<1::real}" by (rule bounded_subset)
next
  show "\<not> compact {0<..<1::real}"
  proof
    assume "compact {0<..<1::real}"
    then have "closed {0<..<1::real}" by (rule compact_imp_closed)
    then have eqc: "closure {0<..<1::real} = {0<..<1::real}" by (simp only: closure_eq)
    have "1 \<in> closure {0<..<1::real}" by simp
    then have "1 \<in> {0<..<1::real}" by (simp only: eqc)
    then show False by simp
  qed
qed

lemma infinite_in_interval_has_limit:
  fixes E :: "real set"
  assumes "infinite E" "E \<subseteq> {0 .. 1}"
  shows "\<exists>x\<in>{0 .. 1}. x islimpt E"
proof -
  have "compact {0 .. 1::real}" by (rule compact_interval)
  from this assms show ?thesis by (rule Heine_Borel_imp_Bolzano_Weierstrass)
qed

lemma weierstrass:
  fixes E :: "real set"
  assumes infE: "infinite E" and bd: "bounded E"
  shows "\<exists>x. x islimpt E"
proof -
  have comp: "compact (closure E)" using bd by simp
  have sub: "E \<subseteq> closure E" by (rule closure_subset)
  from comp infE sub have "\<exists>x\<in>closure E. x islimpt E"
    by (rule Heine_Borel_imp_Bolzano_Weierstrass)
  then obtain x where xlim: "x islimpt E" by (rule bexE)
  from xlim show ?thesis by (rule exI)
qed

end
