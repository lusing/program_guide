theory OpenClosed
  imports "HOL-Analysis.Analysis"
begin

(* 第 10 章 闭集和开集：Isabelle 通道。
   证明只用 simp 和单步规则，避免 auto/blast 在无限交上搜索。
   源码用 Isabelle 实体写法。 *)

lemma open_iff_compl_closed: "open (E :: real set) \<longleftrightarrow> closed (- E)"
  by (simp add: open_closed)

lemma closed_iff_compl_open: "closed (F :: real set) \<longleftrightarrow> open (- F)"
  by (simp add: closed_open)

lemma open_union_any:
  assumes "\<forall>S\<in>K. open S"
  shows "open (\<Union>K)"
  using assms by (rule open_Union)

lemma closed_inter_any:
  assumes "\<forall>S\<in>K. closed S"
  shows "closed (\<Inter>K)"
  using assms by (rule closed_Inter)

lemma open_inter_two:
  "open (G1 :: real set) \<Longrightarrow> open G2 \<Longrightarrow> open (G1 \<inter> G2)"
  by (rule open_Int)

lemma closed_union_two:
  "closed (F1 :: real set) \<Longrightarrow> closed F2 \<Longrightarrow> closed (F1 \<union> F2)"
  by (rule closed_Un)

(* \<Inter> B(0, 1/(n+1)) = {0}。 *)
lemma nested_open_inter:
  "(\<Inter>n::nat. ball (0::real) (inverse (of_nat (Suc n)))) = {0}"
proof (rule equalityI)
  show "(\<Inter>n::nat. ball (0::real) (inverse (of_nat (Suc n)))) \<subseteq> {0}"
  proof
    fix x :: real
    assume xmem: "x \<in> (\<Inter>n::nat. ball (0::real) (inverse (of_nat (Suc n))))"
    show "x \<in> {0}"
    proof (rule ccontr)
      assume "x \<notin> {0}"
      then have pos: "0 < \<bar>x\<bar>" by simp
      from reals_Archimedean[OF pos] obtain n where
        nlt: "inverse (of_nat (Suc n)) < \<bar>x\<bar>" ..
      have "x \<in> ball (0::real) (inverse (of_nat (Suc n)))"
        using xmem by simp
      then have "dist x (0::real) < inverse (of_nat (Suc n))"
        by simp
      then have "\<bar>x\<bar> < inverse (of_nat (Suc n))"
        by (simp add: dist_real_def)
      with nlt show False by simp
    qed
  qed
next
  show "{0} \<subseteq> (\<Inter>n::nat. ball (0::real) (inverse (of_nat (Suc n))))"
  proof
    fix x :: real
    assume "x \<in> {0}"
    then have xz: "x = 0" by simp
    show "x \<in> (\<Inter>n::nat. ball (0::real) (inverse (of_nat (Suc n))))"
    proof (rule INT_I)
      fix n :: nat
      assume "n \<in> UNIV"
      have "dist (0::real) 0 < inverse (of_nat (Suc n))" by simp
      then have "0 \<in> ball (0::real) (inverse (of_nat (Suc n)))" by simp
      then show "x \<in> ball (0::real) (inverse (of_nat (Suc n)))"
        using xz by simp
    qed
  qed
qed

lemma not_open_zero: "\<not> open {0::real}"
proof
  assume op: "open {0::real}"
  from op have ex: "\<exists>\<epsilon>>0. ball (0::real) \<epsilon> \<subseteq> {0}"
    by (simp add: open_contains_ball)
  then obtain \<epsilon> :: real where conj: "0 < \<epsilon> \<and> ball (0::real) \<epsilon> \<subseteq> {0}"
    by (rule exE)
  from conj have e: "0 < \<epsilon>" by (rule conjunct1)
  from conj have sub: "ball (0::real) \<epsilon> \<subseteq> {0}" by (rule conjunct2)
  have mem: "\<epsilon> / 2 \<in> ball (0::real) \<epsilon>"
  proof -
    have "dist (\<epsilon> / 2) (0::real) = \<epsilon> / 2"
      using e by (simp add: dist_real_def)
    also have "\<epsilon> / 2 < \<epsilon>"
      using e by simp
    finally have "dist (\<epsilon> / 2) (0::real) < \<epsilon>" .
    then show ?thesis by simp
  qed
  have "\<epsilon> / 2 \<in> {0::real}"
    using sub mem by (rule subsetD)
  then have "\<epsilon> / 2 = (0::real)" by simp
  with e show False by simp
qed

lemma nested_inter_not_open:
  "\<not> open (\<Inter>n::nat. ball (0::real) (inverse (of_nat (Suc n))))"
  using nested_open_inter not_open_zero by simp

(* \<Union> [0, 2 - 1/(n+1)] 不闭：右端点逼近 2，但 2 不属于任何一项。 *)
lemma not_closed_nested_union:
  "\<not> closed (\<Union>n::nat. {0::real .. 2 - inverse (of_nat (Suc n))})"
proof
  assume c: "closed (\<Union>n::nat. {0::real .. 2 - inverse (of_nat (Suc n))})"
  have in_cl: "(2::real) \<in> closure (\<Union>n::nat. {0 .. 2 - inverse (of_nat (Suc n))})"
  proof (unfold closure_approachable, intro allI impI)
    fix \<epsilon> :: real
    assume epos: "0 < \<epsilon>"
    from reals_Archimedean[OF epos] obtain n where
      nlt: "inverse (of_nat (Suc n)) < \<epsilon>" ..
    let ?y = "2 - inverse (of_nat (Suc n) :: real)"
    have inv_le: "inverse (of_nat (Suc n) :: real) \<le> 1"
      by (simp add: inverse_le_1_iff)
    have "0 \<le> (2::real) - inverse (of_nat (Suc n))"
      using inv_le by simp
    then have yin: "?y \<in> {0::real .. 2 - inverse (of_nat (Suc n))}"
      by simp
    have yun: "?y \<in> (\<Union>n::nat. {0::real .. 2 - inverse (of_nat (Suc n))})"
      apply (rule UN_I[where a=n])
       apply (rule UNIV_I)
      apply (rule yin)
      done
    have "dist ?y (2::real) = inverse (of_nat (Suc n))"
      by (simp add: dist_real_def)
    also have "inverse (of_nat (Suc n) :: real) < \<epsilon>"
      using nlt by simp
    finally have dlt: "dist ?y (2::real) < \<epsilon>" .
    show "\<exists>y\<in>\<Union>n::nat. {0::real .. 2 - inverse (of_nat (Suc n))}. dist y 2 < \<epsilon>"
      using dlt yun by (rule bexI)
  qed
  have notin: "(2::real) \<notin> (\<Union>n::nat. {0 .. 2 - inverse (of_nat (Suc n))})"
  proof
    assume "2 \<in> (\<Union>n::nat. {0::real .. 2 - inverse (of_nat (Suc n))})"
    then obtain n where nin: "2 \<in> {0::real .. 2 - inverse (of_nat (Suc n))}" ..
    then have "2 \<le> 2 - inverse (of_nat (Suc n) :: real)" by simp
    moreover have "0 < inverse (of_nat (Suc n) :: real)" by simp
    ultimately show False by simp
  qed
  have eqc: "closure (\<Union>n::nat. {0::real .. 2 - inverse (of_nat (Suc n))}) =
      (\<Union>n::nat. {0 .. 2 - inverse (of_nat (Suc n))})"
    using c by (simp only: closure_eq)
  have "(2::real) \<in> (\<Union>n::nat. {0 .. 2 - inverse (of_nat (Suc n))})"
    using in_cl by (simp only: eqc)
  with notin show False by simp
qed

lemma closure_of_open_interval: "closure {-3<..<3::real} = {-3..3}"
  by simp

lemma closure_is_closed: "closed (closure (E :: real set))"
  by simp

lemma closure_eq_iff_closed: "closure (E :: real set) = E \<longleftrightarrow> closed E"
  by (rule closure_eq)

lemma closure_smallest:
  fixes E F :: "real set"
  assumes "E \<subseteq> F" "closed F"
  shows "closure E \<subseteq> F"
  using assms by (rule closure_minimal)

lemma sup_in_closure:
  fixes E :: "real set"
  assumes "E \<noteq> {}" "bdd_above E"
  shows "Sup E \<in> closure E"
  using assms by (rule closure_contains_Sup)

lemma inf_in_closure:
  fixes E :: "real set"
  assumes "E \<noteq> {}" "bdd_below E"
  shows "Inf E \<in> closure E"
  using assms by (rule closure_contains_Inf)

lemma sup_in_closed:
  fixes E :: "real set"
  assumes "E \<noteq> {}" "bdd_above E" "closed E"
  shows "Sup E \<in> E"
proof -
  have "Sup E \<in> closure E"
    using assms(1) assms(2) by (rule closure_contains_Sup)
  also have "closure E = E"
    using assms(3) by (simp only: closure_eq)
  finally show ?thesis .
qed

lemma endpoints_in_punctured:
  "-3 \<in> {-3..<0::real} \<union> {0<..3}"
  "3 \<in> {-3..<0::real} \<union> {0<..3}"
  "0 \<notin> {-3..<0::real} \<union> {0<..3}"
  by simp_all

lemma punctured_not_closed: "\<not> closed ({-3..<0::real} \<union> {0<..3})"
proof
  assume c: "closed ({-3..<0::real} \<union> {0<..3})"
  have sub: "{0<..<3::real} \<subseteq> {-3..<0} \<union> {0<..3}"
  proof
    fix x :: real
    assume "x \<in> {0<..<3}"
    then have "x \<in> {0<..3}" by simp
    then show "x \<in> {-3..<0::real} \<union> {0<..3}" by simp
  qed
  have cin: "0 \<in> closure {0<..<3::real}" by simp
  have csub: "closure {0<..<3::real} \<subseteq> closure ({-3..<0::real} \<union> {0<..3})"
    using sub by (rule closure_mono)
  have in_cl0: "0 \<in> closure ({-3..<0::real} \<union> {0<..3})"
    using csub cin by (rule subsetD)
  have eqc: "closure ({-3..<0::real} \<union> {0<..3}) = {-3..<0} \<union> {0<..3}"
    using c by (simp only: closure_eq)
  have "0 \<in> {-3..<0::real} \<union> {0<..3}"
    using in_cl0 by (simp only: eqc)
  then show False
  proof (elim UnE)
    assume "0 \<in> {-3..<0::real}"
    then show False by simp
  next
    assume "0 \<in> {0<..3::real}"
    then show False by simp
  qed
qed

lemma rel_open_iff:
  "openin (top_of_set (Y :: real set)) E \<longleftrightarrow> (\<exists>G. open G \<and> E = Y \<inter> G)"
  by (simp add: openin_open)

lemma rel_open_half:
  "openin (top_of_set {0::real..<2}) ({0..<2} \<inter> {-1<..<1})"
  by (simp add: openin_open_Int)

lemma not_open_half: "\<not> open {0::real..<1}"
proof
  assume op: "open {0::real..<1}"
  from op have ex: "\<exists>\<epsilon>>0. ball (0::real) \<epsilon> \<subseteq> {0..<1}"
    by (simp add: open_contains_ball)
  then obtain \<epsilon> :: real where conj: "0 < \<epsilon> \<and> ball (0::real) \<epsilon> \<subseteq> {0..<1}"
    by (rule exE)
  from conj have e: "0 < \<epsilon>" by (rule conjunct1)
  from conj have sub: "ball (0::real) \<epsilon> \<subseteq> {0..<1}" by (rule conjunct2)
  have mem: "- (\<epsilon> / 2) \<in> ball (0::real) \<epsilon>"
  proof -
    have "dist (- (\<epsilon> / 2)) (0::real) = \<epsilon> / 2"
      using e by (simp add: dist_real_def)
    also have "\<epsilon> / 2 < \<epsilon>"
      using e by simp
    finally have "dist (- (\<epsilon> / 2)) (0::real) < \<epsilon>" .
    then show ?thesis by simp
  qed
  have "- (\<epsilon> / 2) \<in> {0::real..<1}"
    using sub mem by (rule subsetD)
  then have "0 \<le> - (\<epsilon> / 2)" by simp
  with e show False by simp
qed

lemma rel_closed_half:
  "closedin (top_of_set {0::real..<2}) ({0..<2} \<inter> {1..})"
  by (simp add: closedin_closed_Int)

lemma not_closed_half: "\<not> closed {1::real..<2}"
proof
  assume c: "closed {1::real..<2}"
  have in2: "(2::real) \<in> closure {1..<2}" by simp
  have eqc: "closure {1::real..<2} = {1..<2}"
    using c by (simp only: closure_eq)
  have "(2::real) \<in> {1..<2}"
    using in2 by (simp only: eqc)
  then show False by simp
qed

end
