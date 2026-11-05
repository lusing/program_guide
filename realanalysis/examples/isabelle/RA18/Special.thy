theory Special
  imports "HOL-Analysis.Analysis"
begin

(* 第 18 章 特殊序列：Isabelle 通道。
   1/(n+1)^2 由幂得到，调和序列的一半被夹逼到 0，
   (1/2)^n 趋于 0，n 次方根和常数的 n 次方根都趋于 1。 *)

lemma inv_square:
  "(\<lambda>n. inverse (real (Suc n)) ^ 2) \<longlonglongrightarrow> (0::real)"
proof -
  have "(\<lambda>n. inverse (real (Suc n)) ^ 2) \<longlonglongrightarrow> (0::real) ^ 2"
    by (rule tendsto_power[OF LIMSEQ_inverse_real_of_nat])
  then show ?thesis by simp
qed

lemma squeezed_half:
  "(\<lambda>n. inverse (real (Suc n)) / 2) \<longlonglongrightarrow> (0::real)"
proof (rule tendsto_sandwich
    [where f="\<lambda>_::nat. 0::real" and h="\<lambda>n. inverse (real (Suc n))"
      and c="0::real" and net=sequentially])
  show "eventually (\<lambda>n. (0::real) \<le> inverse (real (Suc n)) / 2) sequentially"
    by (rule always_eventually) simp
  show "eventually (\<lambda>n. inverse (real (Suc n)) / 2 \<le> inverse (real (Suc n))) sequentially"
    by (rule always_eventually) simp
  show "(\<lambda>_::nat. (0::real)) \<longlonglongrightarrow> 0"
    by (rule tendsto_const)
  show "(\<lambda>n. inverse (real (Suc n))) \<longlonglongrightarrow> 0"
    by (rule LIMSEQ_inverse_real_of_nat)
qed

lemma half_pow: "(\<lambda>n. ((1::real) / 2) ^ n) \<longlonglongrightarrow> 0"
proof (rule LIMSEQ_power_zero)
  show "norm ((1::real) / 2) < 1" by simp
qed

lemma root_n: "(\<lambda>n. root n n) \<longlonglongrightarrow> 1"
  by (rule LIMSEQ_root)

lemma root_two: "(\<lambda>n. root n (2::real)) \<longlonglongrightarrow> 1"
  by (rule LIMSEQ_root_const) simp

lemma binomial_step: "(1::real) + 2 * (1 / 2) < (3 / 2) ^ 2"
proof -
  have left: "(1::real) + 2 * (1 / 2) = 2" by simp
  have "(3 / 2 :: real) ^ 2 = (3 / 2) * (3 / 2)"
    by (rule power2_eq_square)
  also have "... = 9 / 4" by simp
  finally have right: "(3 / 2 :: real) ^ 2 = 9 / 4" .
  show ?thesis by (simp add: left right)
qed

lemma eleven_square: "(1::real) / 121 < 1 / 10"
  by simp

end
