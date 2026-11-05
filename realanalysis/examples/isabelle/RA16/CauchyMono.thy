theory CauchyMono
  imports "HOL-Analysis.Analysis"
begin

(* 第 16 章 柯西序列与单调序列：Isabelle 通道。
   收敛推出柯西，实数上二者等价，闭集留下极限，
   1/(n+1) 递减，1-1/(n+1) 递增且有上界，因而收敛到上确界。 *)

lemma conv_imp_cauchy:
  fixes X :: "nat \<Rightarrow> real" and L :: real
  assumes "X \<longlonglongrightarrow> L"
  shows "Cauchy X"
  by (rule LIMSEQ_imp_Cauchy[OF assms])

lemma harmonic_cauchy: "Cauchy (\<lambda>n. inverse (real (Suc n)))"
  by (rule conv_imp_cauchy[OF LIMSEQ_inverse_real_of_nat])

lemma real_cauchy_iff_convergent:
  fixes X :: "nat \<Rightarrow> real"
  shows "Cauchy X \<longleftrightarrow> convergent X"
  by (rule Cauchy_convergent_iff)

lemma closed_keeps_limit:
  fixes s :: "nat \<Rightarrow> real" and E :: "real set" and p :: real
  assumes "closed E" and "\<And>n. s n \<in> E" and "s \<longlonglongrightarrow> p"
  shows "p \<in> E"
  by (rule closed_sequentially[OF assms(1) assms(2) assms(3)])

lemma dist_one_three: "dist (1::real) 3 = 2"
  by (simp add: dist_real_def)

lemma dist_ends: "dist (-3::real) 3 = 6"
  by (simp add: dist_real_def)

lemma harmonic_step:
  "inverse (real (Suc (Suc n))) \<le> inverse (real (Suc n) :: real)"
proof -
  have le: "real (Suc n) \<le> real (Suc (Suc n))" by simp
  have pos: "0 < real (Suc n)" by simp
  show ?thesis by (rule le_imp_inverse_le[OF le pos])
qed

lemma harmonic_dec: "decseq (\<lambda>n. inverse (real (Suc n) :: real))"
  by (rule decseq_SucI, rule harmonic_step)

lemma approach_inc: "incseq (\<lambda>n. (1::real) - inverse (real (Suc n)))"
proof (rule incseq_SucI)
  fix n
  show "(1::real) - inverse (real (Suc n))
          \<le> 1 - inverse (real (Suc (Suc n)))"
    using harmonic_step[of n] by simp
qed

lemma approach_bdd:
  "bdd_above (range (\<lambda>n. (1::real) - inverse (real (Suc n))))"
proof (rule bdd_aboveI)
  fix x
  assume "x \<in> range (\<lambda>n. (1::real) - inverse (real (Suc n)))"
  then obtain n where "x = (1::real) - inverse (real (Suc n))"
    by (rule rangeE)
  then show "x \<le> 1" by simp
qed

lemma approach_to_sup:
  "(\<lambda>n. (1::real) - inverse (real (Suc n))) \<longlonglongrightarrow>
     (SUP i. (1::real) - inverse (real (Suc i)))"
  by (rule LIMSEQ_incseq_SUP[OF approach_bdd approach_inc])

lemma approach_to_one:
  "(\<lambda>n. (1::real) - inverse (real (Suc n))) \<longlonglongrightarrow> 1"
proof -
  have "(\<lambda>n. (1::real) - inverse (real (Suc n))) \<longlonglongrightarrow> 1 - 0"
    by (rule tendsto_diff[OF tendsto_const LIMSEQ_inverse_real_of_nat])
  then show ?thesis by simp
qed

lemma trunc_gap:
  "\<bar>(141::real) / 100 - 1414 / 1000\<bar> < 1 / 100"
proof -
  have eq: "(141::real) / 100 - 1414 / 1000
              = (141 * 1000 - 1414 * 100) / (100 * 1000)"
    by (simp add: diff_frac_eq)
  have num: "(141::real) * 1000 - 1414 * 100 = -400" by simp
  have den: "(100::real) * 1000 = 100000" by simp
  have reduced: "(141::real) / 100 - 1414 / 1000 = - (4 / 1000)"
    using eq num den by simp
  have abs_eq: "\<bar>(141::real) / 100 - 1414 / 1000\<bar> = 4 / 1000"
    using reduced by simp
  have lt: "(4::real) / 1000 < 1 / 100" by simp
  show ?thesis using abs_eq lt by simp
qed

lemma eleven_twelve:
  "\<bar>inverse (11::real) - inverse (12::real)\<bar> < inverse (10::real)"
proof -
  have step: "inverse (11::real) - inverse 12
                = inverse 11 * (12 - 11) * inverse 12"
    by (simp add: division_ring_inverse_diff)
  have prod: "inverse (11::real) * inverse 12 = inverse (11 * 12)"
    by (rule inverse_mult_distrib[symmetric])
  have arith: "inverse (11::real) * (12 - 11) * inverse 12 = inverse 132"
  proof -
    have "inverse (11::real) * (12 - 11) * inverse 12 = inverse (11 * 12)"
      using prod by simp
    then show ?thesis by simp
  qed
  have eq: "inverse (11::real) - inverse 12 = inverse 132"
    using step arith by simp
  have abs_eq: "\<bar>inverse (11::real) - inverse 12\<bar> = inverse 132"
    by (simp add: eq)
  have smaller: "inverse (132::real) < inverse 10"
    by (simp add: inverse_less_iff_less)
  show ?thesis by (simp add: abs_eq smaller)
qed

end
