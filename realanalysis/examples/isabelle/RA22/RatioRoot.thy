theory RatioRoot
  imports "HOL-Analysis.Analysis"
begin

(* 第 22 章 比值判别法与根值判别法（补充章）：Isabelle 通道。
   两条判别法都归结为和一条几何级数比较。 *)

lemma ratio_test_step: "2 ^ 3 / fact 3 / (2 ^ 2 / fact 2) = (2::real) / 3"
  by (simp add: fact_numeral)

lemma ratio_series_summable: "summable (\<lambda>n. (2::real) ^ n / fact n)"
proof (rule summable_ratio_test[where c = "3 / 4" and N = 2])
  show "(3::real) / 4 < 1" by simp
  fix n :: nat
  assume n: "2 \<le> n"
  have pos: "0 < (2::real) ^ n / fact n" by (simp add: fact_gt_zero)
  have "norm ((2::real) ^ Suc n / fact (Suc n)) = 2 ^ Suc n / fact (Suc n)"
    by (simp add: fact_gt_zero)
  also have "... = (2 ^ n / fact n) * (2 / (n + 1))" by (simp add: fact_Suc field_simps)
  also have "... \<le> (2 ^ n / fact n) * (3 / 4)"
  proof -
    have h: "2 / (real n + 1) \<le> (3::real) / 4"
      using n by (simp add: pos_le_divide_eq pos_divide_le_eq)
    from mult_left_mono[OF h, of "2 ^ n / fact n"] pos show ?thesis
      by (simp add: add.commute)
  qed
  also have "... = 3 / 4 * norm ((2::real) ^ n / fact n)" using pos by simp
  finally show "norm ((2::real) ^ Suc n / fact (Suc n)) \<le>
    3 / 4 * norm ((2::real) ^ n / fact n)" .
qed

lemma geometric_two_diverges: "\<not>summable (\<lambda>n. (2::real) ^ n)"
proof -
  have "\<not>norm (2::real) < 1" by simp
  then show ?thesis using summable_geometric_iff[where c="(2::real)"] by blast
qed

lemma root_base_bound:
  "(real n / (2 * n + 1)) ^ n \<le> (3 / 5 :: real) ^ n"
proof (rule power_mono)
  show "real n / (2 * n + 1) \<le> (3 / 5 :: real)"
  proof -
    have "real n / (2 * n + 1) \<le> (3 / 5 :: real) \<longleftrightarrow> real n * 5 \<le> 3 * (2 * n + 1)"
      by (simp add: pos_divide_le_eq pos_le_divide_eq field_simps)
    then show ?thesis by simp
  qed
  show "0 \<le> real n / (2 * n + 1)" by simp
qed

lemma root_series_summable: "summable (\<lambda>n. (real n / (2 * n + 1)) ^ n)"
proof (rule summable_comparison_test')
  show "summable (\<lambda>n. (3 / 5 :: real) ^ n)" by (rule summable_geometric) simp
  fix n :: nat
  assume "n \<ge> 0"
  have "norm ((real n / (2 * n + 1)) ^ n) = (real n / (2 * n + 1)) ^ n"
    by (simp add: power_abs)
  then show "norm ((real n / (2 * n + 1)) ^ n) \<le> (3 / 5 :: real) ^ n"
    using root_base_bound by simp
qed

lemma root_bound_at_two: "(2 / 5 :: real) ^ 2 \<le> (3 / 5) ^ 2" by simp

lemma harmonic_ratio_tendsto_one:
  "(\<lambda>n. real (Suc n) / real (n + 2)) \<longlonglongrightarrow> 1"
proof -
  have h0: "(\<lambda>n. 1 / (real n + 1)) \<longlonglongrightarrow> (0::real)"
    using LIMSEQ_inverse_real_of_nat
    by (simp add: divide_inverse add.commute)
  then have h1: "(\<lambda>n. 1 / (real (Suc n) + 1)) \<longlonglongrightarrow> (0::real)"
    by (rule LIMSEQ_Suc)
  then have h2: "(\<lambda>n. 1 / (real n + 2)) \<longlonglongrightarrow> (0::real)"
    by (simp add: add.commute)
  then have h3: "(\<lambda>n. 1 - 1 / (real n + 2)) \<longlonglongrightarrow> (1::real) - 0"
    by (intro tendsto_diff tendsto_const)
  then have h4: "(\<lambda>n. 1 - 1 / (real n + 2)) \<longlonglongrightarrow> (1::real)" by simp
  have h5: "\<And>n. real (Suc n) / real (n + 2) = (1::real) - 1 / (real n + 2)"
  proof -
    fix n
    have nz: "(real n + 2) \<noteq> (0::real)" by simp
    have "real (Suc n) = (real n + 2) - 1" by simp
    then have "real (Suc n) / real (n + 2) = ((real n + 2) - 1) / (real n + 2)"
      by (simp add: nz)
    also have "... = 1 - 1 / (real n + 2)" using nz by (simp add: field_simps)
    finally show "real (Suc n) / real (n + 2) = 1 - 1 / (real n + 2)" .
  qed
  have "(\<lambda>n. real (Suc n) / real (n + 2)) = (\<lambda>n. 1 - 1 / (real n + 2))"
  proof
    fix n
    show "real (Suc n) / real (n + 2) = 1 - 1 / (real n + 2)" using h5[of n]
      by (simp add: add.commute)
  qed
  then show ?thesis by (simp add: h4)
qed

lemma squares_ratio_tendsto_one:
  "(\<lambda>n. (real (Suc n) / real (n + 2)) ^ 2) \<longlonglongrightarrow> (1::real)"
proof -
  have "(\<lambda>n. (real (Suc n) / real (n + 2)) ^ 2) \<longlonglongrightarrow> 1 ^ (2::nat)"
    by (intro tendsto_power harmonic_ratio_tendsto_one)
  then show ?thesis by simp
qed

lemma shifted_harmonic_diverges:
  "\<not>summable (\<lambda>n. 1 / (real (Suc n) :: real))"
proof -
  have "\<not>summable (\<lambda>n. 1 / (real n :: real))"
    using not_summable_harmonic[where 'a=real] by (simp add: inverse_eq_divide)
  moreover have "summable (\<lambda>n. 1 / (real (Suc n) :: real)) = summable (\<lambda>n. 1 / (real n :: real))"
    by (rule summable_Suc_iff)
  ultimately show ?thesis by blast
qed

lemma shifted_squares_summable:
  "summable (\<lambda>n. 1 / (real (Suc n) :: real) ^ 2)"
proof -
  have "summable (\<lambda>n. inverse (of_nat n ^ (2::nat) :: real))"
    by (rule inverse_power_summable) simp
  then have "summable (\<lambda>n. inverse (of_nat (Suc n) ^ (2::nat) :: real))"
    by (subst (asm) summable_Suc_iff[symmetric]) simp
  then show ?thesis by (simp add: inverse_eq_divide)
qed

end
