theory SeriesBasics
  imports "HOL-Analysis.Analysis"
begin

(* 第 19 章 级数：Isabelle 通道。
   级数收敛当且仅当部分和满足柯西准则，收敛则通项趋于 0。
   |x|<1 时几何级数求和，x=1/2 的部分和等于闭式，
   从 n=1 起的 (2/3)^n 加起来是 2。 *)

lemma series_cauchy:
  "summable (f :: nat \<Rightarrow> real) \<longleftrightarrow>
    (\<forall>e>0. \<exists>N. \<forall>m\<ge>N. \<forall>n. norm (sum f {m..<n}) < e)"
  by (rule summable_Cauchy)

lemma terms_to_zero:
  fixes f :: "nat \<Rightarrow> real"
  assumes "summable f"
  shows "f \<longlonglongrightarrow> 0"
  by (rule summable_LIMSEQ_zero[OF assms])

lemma half_summable: "summable (\<lambda>n. ((1::real) / 2) ^ n)"
  by (rule summable_geometric) simp

lemma half_sum: "suminf (\<lambda>n. ((1::real) / 2) ^ n) = 2"
proof -
  have "suminf (\<lambda>n. ((1::real) / 2) ^ n) = 1 / (1 - 1 / 2)"
    by (rule suminf_geometric) simp
  then show ?thesis by simp
qed

lemma half_partial:
  "(\<Sum>i<3. ((1::real) / 2) ^ i) = (1 - ((1::real) / 2) ^ 3) / (1 - 1 / 2)"
proof -
  have "(\<Sum>i<3. ((1::real) / 2) ^ i) = (((1::real) / 2) ^ 3 - 1) / (1 / 2 - 1)"
    by (rule geometric_sum) simp
  also have "... = (1 - ((1::real) / 2) ^ 3) / (1 - 1 / 2)"
    by simp
  finally show ?thesis .
qed

lemma two_thirds: "suminf (\<lambda>n. ((2::real) / 3) ^ n) - 1 = 2"
proof -
  have "suminf (\<lambda>n. ((2::real) / 3) ^ n) = 1 / (1 - 2 / 3)"
    by (rule suminf_geometric) simp
  then show ?thesis by simp
qed

lemma harmonic_four: "(1::real) + 1 / 2 + 1 / 3 + 1 / 4 > 2"
  by simp

lemma harmonic_group: "(1::real) + 1 / 2 + 1 / 4 + 1 / 4 = 2"
  by simp

lemma one_not_small: "\<not> \<bar>(1::real)\<bar> < 1 / 2"
  by simp

end
