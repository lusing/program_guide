theory Filters
  imports "ZF.CardinalArith"
begin

text \<open>
第 07 章 滤子与理想：ZF 内的手工构造。

ZF 库没有滤子理论（那是 HOL 侧的资产）；集合论侧的滤子
公理平凡地可在 ZF 内陈述。本章验证：主滤子满足滤子公理、
对偶理想的确是理想、滤子的交仍是滤子（引理 7.1a）。
\<close>

definition IsFilter :: "[i, i] \<Rightarrow> o" where
  "IsFilter(F, S) \<equiv>
     F \<subseteq> Pow(S) \<and>
     S \<in> F \<and> 0 \<notin> F \<and>
     (\<forall>X\<in>F. \<forall>Y\<in>F. X \<inter> Y \<in> F) \<and>
     (\<forall>X\<in>F. \<forall>Y\<in>Pow(S). X \<subseteq> Y \<longrightarrow> Y \<in> F)"

definition DualIdeal :: "[i, i] \<Rightarrow> i" where
  "DualIdeal(F, S) \<equiv> {S - X . X \<in> F}"

section \<open>主滤子\<close>

lemma principal_is_filter:
  assumes "X0 \<subseteq> S" "X0 \<noteq> 0"
  shows "IsFilter({Y \<in> Pow(S) . X0 \<subseteq> Y}, S)"
  unfolding IsFilter_def
proof (intro conjI)
  show "{Y \<in> Pow(S) . X0 \<subseteq> Y} \<subseteq> Pow(S)" by auto
next
  show "S \<in> {Y \<in> Pow(S) . X0 \<subseteq> Y}" using assms by auto
next
  show "0 \<notin> {Y \<in> Pow(S) . X0 \<subseteq> Y}"
    using assms by auto
next
  show "\<forall>X\<in>{Y \<in> Pow(S) . X0 \<subseteq> Y}. \<forall>Y\<in>{Y \<in> Pow(S) . X0 \<subseteq> Y}.
           X \<inter> Y \<in> {Y \<in> Pow(S) . X0 \<subseteq> Y}" by blast
next
  show "\<forall>X\<in>{Y \<in> Pow(S) . X0 \<subseteq> Y}. \<forall>Y\<in>Pow(S). X \<subseteq> Y \<longrightarrow>
           Y \<in> {Y \<in> Pow(S) . X0 \<subseteq> Y}" by blast
qed

section \<open>对偶理想（Jech (7.3)）\<close>

lemma dual_ideal_is_ideal:
  assumes "IsFilter(F, S)"
  shows "0 \<in> DualIdeal(F, S) \<and>
         (\<forall>X\<in>DualIdeal(F, S). \<forall>Y\<in>DualIdeal(F, S).
             X \<union> Y \<in> DualIdeal(F, S)) \<and>
         (\<forall>X\<in>DualIdeal(F, S). \<forall>Y\<in>Pow(S). Y \<subseteq> X \<longrightarrow>
             Y \<in> DualIdeal(F, S))"
proof (intro conjI)
  show "0 \<in> DualIdeal(F, S)"
    unfolding DualIdeal_def using assms unfolding IsFilter_def by force
next
  show "\<forall>X\<in>DualIdeal(F, S). \<forall>Y\<in>DualIdeal(F, S).
           X \<union> Y \<in> DualIdeal(F, S)"
  proof (intro ballI)
    fix X Y
    assume "X \<in> DualIdeal(F, S)" "Y \<in> DualIdeal(F, S)"
    then obtain A B where "A \<in> F" "B \<in> F" "X = S - A" "Y = S - B"
      unfolding DualIdeal_def by blast
    then have eq: "X \<union> Y = S - (A \<inter> B)" by blast
    have "A \<inter> B \<in> F" using assms \<open>A \<in> F\<close> \<open>B \<in> F\<close>
      unfolding IsFilter_def by blast
    with eq show "X \<union> Y \<in> DualIdeal(F, S)"
      unfolding DualIdeal_def by blast
  qed
next
  show "\<forall>X\<in>DualIdeal(F, S). \<forall>Y\<in>Pow(S). Y \<subseteq> X \<longrightarrow>
           Y \<in> DualIdeal(F, S)"
  proof (intro ballI impI)
    fix X Y
    assume "X \<in> DualIdeal(F, S)" "Y \<in> Pow(S)" "Y \<subseteq> X"
    then obtain A where "A \<in> F" "X = S - A"
      unfolding DualIdeal_def by blast
    have sub: "A \<subseteq> S - Y"
    proof (rule subsetI)
      fix a
      assume "a \<in> A"
      then have "a \<in> S" using assms \<open>A \<in> F\<close>
        unfolding IsFilter_def by blast
      moreover have "a \<notin> Y"
      proof
        assume "a \<in> Y"
        then have "a \<in> X" using \<open>Y \<subseteq> X\<close> by blast
        with \<open>X = S - A\<close> have "a \<notin> A" by blast
        with \<open>a \<in> A\<close> show False by blast
      qed
      ultimately show "a \<in> S - Y" by blast
    qed
    have "S - Y \<in> Pow(S)" using \<open>Y \<in> Pow(S)\<close> by blast
    then have "S - Y \<in> F" using assms \<open>A \<in> F\<close> sub
      unfolding IsFilter_def by blast
    moreover have "Y = S - (S - Y)" using \<open>Y \<in> Pow(S)\<close> by blast
    ultimately show "Y \<in> DualIdeal(F, S)" unfolding DualIdeal_def by blast
  qed
qed

end
