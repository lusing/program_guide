theory Sequences
  imports "HOL-Analysis.Analysis"
begin

(* 第 14 章 序列与收敛：Isabelle 通道。
   1/(n+1) 趋于 0、常数序列、极限唯一、收敛蕴含值域有界、平方发散。
   极限的四则运算属于下一章。 *)

lemma harmonic_to_zero:
  "(\<lambda>n. inverse (real (Suc n))) \<longlonglongrightarrow> (0::real)"
  by (rule LIMSEQ_inverse_real_of_nat)

lemma harmonic_positive:
  "0 < inverse (real (Suc n) :: real)"
  by simp

lemma harmonic_le_one:
  "inverse (real (Suc n) :: real) \<le> 1"
proof -
  have le: "(1::real) \<le> real (Suc n)" by simp
  have nonneg: "0 \<le> inverse (real (Suc n) :: real)" by simp
  have "inverse (real (Suc n) :: real) * 1 \<le> inverse (real (Suc n)) * real (Suc n)"
    by (rule mult_left_mono[OF le nonneg])
  then show ?thesis by simp
qed

lemma const_to_one:
  "(\<lambda>n::nat. 1::real) \<longlonglongrightarrow> 1"
  by (rule tendsto_const)

lemma limit_unique:
  fixes s :: "nat \<Rightarrow> real" and p q :: real
  assumes "s \<longlonglongrightarrow> p" and "s \<longlonglongrightarrow> q"
  shows "p = q"
  using assms by (rule LIMSEQ_unique)

lemma convergent_range_bounded:
  fixes s :: "nat \<Rightarrow> real" and p :: real
  assumes "s \<longlonglongrightarrow> p"
  shows "bounded (range s)"
  by (rule convergent_imp_bounded[OF assms])

lemma squares_unbounded:
  "\<not> bounded (range (\<lambda>n::nat. (real n) ^ 2))"
proof
  assume b: "bounded (range (\<lambda>n::nat. (real n) ^ 2))"
  then have "\<exists>M. \<forall>x\<in>range (\<lambda>n::nat. (real n) ^ 2). norm x \<le> M"
    by (simp only: bounded_iff)
  then obtain M where M: "\<forall>x\<in>range (\<lambda>n::nat. (real n) ^ 2). norm x \<le> M"
    by (rule exE)
  have zero_mem: "(real 0) ^ 2 \<in> range (\<lambda>n::nat. (real n) ^ 2)"
    by (rule rangeI)
  have "norm ((real 0) ^ 2) \<le> M"
    by (rule bspec[OF M zero_mem])
  then have M0: "0 \<le> M" by simp
  obtain n where nM: "M + 1 < real n"
    using reals_Archimedean2[where x = "M + 1"] by (rule exE)
  have one_le_M: "(1::real) \<le> M + 1" using M0 by simp
  have one_lt: "(1::real) < real n"
    by (rule le_less_trans[OF one_le_M nM])
  have n_ge: "1 \<le> n"
    using one_lt by simp
  have le1: "(1::real) \<le> real n" using n_ge by simp
  have nonneg_n: "0 \<le> real n" by simp
  have n_le_sq: "real n \<le> (real n) ^ 2"
  proof -
    have "real n * 1 \<le> real n * real n"
      by (rule mult_left_mono[OF le1 nonneg_n])
    then show ?thesis by (simp add: power2_eq_square)
  qed
  have mem: "(real n) ^ 2 \<in> range (\<lambda>k::nat. (real k) ^ 2)"
    by (rule rangeI)
  have "norm ((real n) ^ 2) \<le> M"
    by (rule bspec[OF M mem])
  then have sq_le: "(real n) ^ 2 \<le> M" by simp
  have step: "M + 1 < (real n) ^ 2"
    by (rule less_le_trans[OF nM n_le_sq])
  have "M + 1 < M"
    by (rule less_le_trans[OF step sq_le])
  then show False by simp
qed

lemma squares_divergent:
  "\<not> convergent (\<lambda>n::nat. (real n) ^ 2)"
proof
  assume "convergent (\<lambda>n::nat. (real n) ^ 2)"
  then have "\<exists>p::real. (\<lambda>n. (real n) ^ 2) \<longlonglongrightarrow> p"
    by (simp only: convergent_def)
  then obtain p where "(\<lambda>n::nat. (real n) ^ 2) \<longlonglongrightarrow> p"
    by (rule exE)
  then have "bounded (range (\<lambda>n::nat. (real n) ^ 2))"
    by (rule convergent_imp_bounded)
  then show False by (rule notE[OF squares_unbounded])
qed

end
