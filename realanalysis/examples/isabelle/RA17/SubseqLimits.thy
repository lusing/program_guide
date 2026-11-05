theory SubseqLimits
  imports "HOL-Analysis.Analysis"
begin

(* 第 17 章 子序列极限：Isabelle 通道。
   n² 趋于正无穷，-5n 趋于负无穷，(-1)^n 并不趋于正无穷，
   常数序列的上极限和下极限都是 1，比较保持次序。 *)

lemma squares_to_top:
  "filterlim (\<lambda>n::nat. (real n) ^ 2) at_top sequentially"
proof (rule filterlim_pow_at_top[where n=2])
  show "(0::nat) < 2" by simp
  show "filterlim real at_top sequentially"
    by (rule filterlim_real_sequentially)
qed

lemma neg_five_to_bot:
  "filterlim (\<lambda>n::nat. (-5::real) * real n) at_bot sequentially"
proof (rule filterlim_cmult_at_bot_at_top
    [where c="-5::real" and h=real and F=sequentially and G=at_bot])
  show "filterlim real at_top sequentially"
    by (rule filterlim_real_sequentially)
  show "(-5::real) \<noteq> 0" by simp
  show "at_bot = (if (-5::real) > 0 then at_top else at_bot)" by simp
qed

lemma odd_pow_minus: "(-1::real) ^ (2 * k + 1) = -1"
  by (simp add: power_add power_mult)

lemma odd_strict_mono: "strict_mono (\<lambda>k::nat. 2 * k + 1)"
  by (rule strict_monoI) simp

lemma alt_not_top:
  "\<not> filterlim (\<lambda>n. (-1::real) ^ n) at_top sequentially"
proof
  assume h: "filterlim (\<lambda>n. (-1::real) ^ n) at_top sequentially"
  have comp: "filterlim (\<lambda>k. (-1::real) ^ (2 * k + 1)) at_top sequentially"
    by (rule filterlim_compose[OF h filterlim_subseq[OF odd_strict_mono]])
  then have const: "filterlim (\<lambda>k::nat. -1::real) at_top sequentially"
    by (simp add: odd_pow_minus)
  then have allZ: "\<forall>Z::real. eventually (\<lambda>k::nat. Z \<le> -1) sequentially"
    by (simp add: filterlim_at_top)
  have ev: "eventually (\<lambda>k::nat. (0::real) \<le> -1) sequentially"
    by (rule spec[OF allZ])
  then have "eventually (\<lambda>k::nat. False) sequentially" by simp
  then show False by (simp add: eventually_False sequentially_bot)
qed

lemma const_limsup: "Limsup sequentially (\<lambda>n::nat. 1::ereal) = 1"
  by (rule Limsup_const[OF sequentially_bot])

lemma const_liminf: "Liminf sequentially (\<lambda>n::nat. 1::ereal) = 1"
  by (rule Liminf_const[OF sequentially_bot])

lemma limsup_bound:
  fixes X :: "nat \<Rightarrow> ereal" and C :: ereal
  shows "C \<ge> Limsup sequentially X \<longleftrightarrow>
    (\<forall>y. C < y \<longrightarrow> eventually (\<lambda>n. X n < y) sequentially)"
  by (rule Limsup_le_iff)

lemma limsup_keeps_order:
  fixes s t :: "nat \<Rightarrow> ereal"
  assumes "eventually (\<lambda>n. s n \<le> t n) sequentially"
  shows "Limsup sequentially s \<le> Limsup sequentially t"
  by (rule Limsup_mono[OF assms])

lemma liminf_keeps_order:
  fixes s t :: "nat \<Rightarrow> ereal"
  assumes "eventually (\<lambda>n. s n \<le> t n) sequentially"
  shows "Liminf sequentially s \<le> Liminf sequentially t"
  by (rule Liminf_mono[OF assms])

end
