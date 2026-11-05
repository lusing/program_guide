theory Subsequences
  imports "HOL-Analysis.Analysis"
begin

(* 第 15 章 极限与子序列：Isabelle 通道。
   和、数乘、积、倒数、平面上的分量、子序列保持极限、
   (-1)^n 的偶奇子序列、闭区间上的序列紧。 *)

lemma add_limits:
  fixes s t :: "nat \<Rightarrow> real" and a b :: real
  assumes "s \<longlonglongrightarrow> a" and "t \<longlonglongrightarrow> b"
  shows "(\<lambda>n. s n + t n) \<longlonglongrightarrow> a + b"
  by (rule tendsto_add[OF assms(1) assms(2)])

lemma const_add_limit:
  fixes s :: "nat \<Rightarrow> real" and a c :: real
  assumes "s \<longlonglongrightarrow> a"
  shows "(\<lambda>n. c + s n) \<longlonglongrightarrow> c + a"
  by (rule tendsto_add[OF tendsto_const assms])

lemma const_mul_limit:
  fixes s :: "nat \<Rightarrow> real" and a c :: real
  assumes "s \<longlonglongrightarrow> a"
  shows "(\<lambda>n. c * s n) \<longlonglongrightarrow> c * a"
  by (rule tendsto_mult_left[OF assms])

lemma mul_limits:
  fixes s t :: "nat \<Rightarrow> real" and a b :: real
  assumes "s \<longlonglongrightarrow> a" and "t \<longlonglongrightarrow> b"
  shows "(\<lambda>n. s n * t n) \<longlonglongrightarrow> a * b"
  by (rule tendsto_mult[OF assms(1) assms(2)])

lemma one_plus_harmonic:
  "(\<lambda>n. (1::real) + inverse (real (Suc n))) \<longlonglongrightarrow> 1"
proof -
  have "(\<lambda>n. (1::real) + inverse (real (Suc n))) \<longlonglongrightarrow> 1 + 0"
    by (rule tendsto_add[OF tendsto_const LIMSEQ_inverse_real_of_nat])
  then show ?thesis by simp
qed

lemma inv_limit:
  fixes s :: "nat \<Rightarrow> real" and a :: real
  assumes "s \<longlonglongrightarrow> a" and "a \<noteq> 0"
  shows "(\<lambda>n. inverse (s n)) \<longlonglongrightarrow> inverse a"
  by (rule tendsto_inverse[OF assms(1) assms(2)])

lemma inv_one_plus:
  "(\<lambda>n. inverse ((1::real) + inverse (real (Suc n)))) \<longlonglongrightarrow> 1"
proof -
  have h: "(\<lambda>n. (1::real) + inverse (real (Suc n))) \<longlonglongrightarrow> 1"
    by (rule one_plus_harmonic)
  have nz: "(1::real) \<noteq> 0" by simp
  have "(\<lambda>n. inverse ((1::real) + inverse (real (Suc n)))) \<longlonglongrightarrow> inverse (1::real)"
    by (rule tendsto_inverse[OF h nz])
  then show ?thesis by simp
qed

lemma harmonic_pair:
  "(\<lambda>n. (inverse (real (Suc n)), 3::real)) \<longlonglongrightarrow> (0, 3)"
  by (rule tendsto_Pair[OF LIMSEQ_inverse_real_of_nat tendsto_const])

lemma subseq_preserves:
  fixes X :: "nat \<Rightarrow> real" and L :: real and f :: "nat \<Rightarrow> nat"
  assumes "X \<longlonglongrightarrow> L" and "strict_mono f"
  shows "(X \<circ> f) \<longlonglongrightarrow> L"
  by (rule LIMSEQ_subseq_LIMSEQ[OF assms(1) assms(2)])

lemma seq_is_subseq:
  fixes X :: "nat \<Rightarrow> real" and L :: real
  assumes "\<And>f. strict_mono f \<Longrightarrow> (X \<circ> f) \<longlonglongrightarrow> L"
  shows "X \<longlonglongrightarrow> L"
proof -
  have "(X \<circ> id) \<longlonglongrightarrow> L"
    by (rule assms[OF strict_mono_id])
  then show ?thesis by (simp add: comp_id)
qed

lemma even_strict_mono: "strict_mono (\<lambda>k::nat. 2 * k)"
  by (rule strict_monoI) simp

lemma odd_strict_mono: "strict_mono (\<lambda>k::nat. 2 * k + 1)"
  by (rule strict_monoI) simp

lemma even_pow_one: "(-1::real) ^ (2 * k) = 1"
  by (simp add: power_mult)

lemma odd_pow_minus: "(-1::real) ^ (2 * k + 1) = -1"
  by (simp add: power_add power_mult)

lemma even_alt: "(\<lambda>k. (-1::real) ^ (2 * k)) \<longlonglongrightarrow> 1"
  by (simp add: even_pow_one tendsto_const)

lemma odd_alt: "(\<lambda>k. (-1::real) ^ (2 * k + 1)) \<longlonglongrightarrow> -1"
  by (simp add: odd_pow_minus tendsto_const)

lemma alternating_not_convergent:
  "\<not> convergent (\<lambda>n. (-1::real) ^ n)"
proof
  assume "convergent (\<lambda>n. (-1::real) ^ n)"
  then have "\<exists>L::real. (\<lambda>n. (-1::real) ^ n) \<longlonglongrightarrow> L"
    by (simp only: convergent_def)
  then obtain L where L: "(\<lambda>n. (-1::real) ^ n) \<longlonglongrightarrow> L"
    by (rule exE)
  have e: "((\<lambda>n. (-1::real) ^ n) \<circ> (\<lambda>k. 2 * k)) \<longlonglongrightarrow> L"
    by (rule LIMSEQ_subseq_LIMSEQ[OF L even_strict_mono])
  have o: "((\<lambda>n. (-1::real) ^ n) \<circ> (\<lambda>k. 2 * k + 1)) \<longlonglongrightarrow> L"
    by (rule LIMSEQ_subseq_LIMSEQ[OF L odd_strict_mono])
  have e1: "(\<lambda>k. (-1::real) ^ (2 * k)) \<longlonglongrightarrow> L"
    using e by (simp add: comp_def)
  have o1: "(\<lambda>k. (-1::real) ^ (2 * k + 1)) \<longlonglongrightarrow> L"
    using o by (simp add: comp_def)
  have L1: "L = 1"
    by (rule LIMSEQ_unique[OF e1 even_alt])
  have Lm: "L = -1"
    by (rule LIMSEQ_unique[OF o1 odd_alt])
  have "(1::real) = -1"
    using L1 Lm by simp
  then show False by simp
qed

lemma unit_seq_compact: "seq_compact {0..1::real}"
  by (rule compact_imp_seq_compact[OF compact_interval])

end
