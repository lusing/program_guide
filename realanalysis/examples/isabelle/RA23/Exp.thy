theory Exp
  imports "HOL-Analysis.Analysis"
begin

(* 第 23 章 数 e 与指数函数（补充章）：Isabelle 通道。
   用级数定义 exp，给出 e 的部分和、上下界与函数方程，
   最后手写 Fourier 证明：e 不是有理数。 *)

(* 指数级数的收敛与求和。 *)

lemma exp_series_sums:
  fixes x :: real
  shows "(\<lambda>n. x ^ n / fact n) sums exp x"
  using exp_converges [of x] by (simp add: field_simps ac_simps)

lemma exp_series_summable:
  fixes x :: real
  shows "summable (\<lambda>n. x ^ n / fact n)"
  by (rule exp_series_sums [THEN sums_summable])

lemma exp_one_sums: "(\<lambda>n. (1::real) / fact n) sums exp 1"
  using exp_series_sums [of "1::real"] by simp

(* e 的前几个部分和。 *)

lemma exp_one_partial: "(\<Sum>m<3. (1::real) / fact m) = 5 / 2"
proof -
  have h: "(\<Sum>m<3. (1::real) / fact m) =
      1 / fact 0 + 1 / fact 1 + 1 / fact 2"
    by (simp add: sum.lessThan_Suc eval_nat_numeral)
  then show ?thesis by (simp add: fact_numeral)
qed

lemma exp_one_partial_four: "(\<Sum>m<4. (1::real) / fact m) = 8 / 3"
proof -
  have h: "(\<Sum>m<4. (1::real) / fact m) =
      1 / fact 0 + 1 / fact 1 + 1 / fact 2 + 1 / fact 3"
    by (simp add: sum.lessThan_Suc eval_nat_numeral)
  then show ?thesis by (simp add: fact_numeral)
qed

lemma exp_one_partial_five: "(\<Sum>m<5. (1::real) / fact m) = 65 / 24"
proof -
  have h: "(\<Sum>m<5. (1::real) / fact m) =
      1 / fact 0 + 1 / fact 1 + 1 / fact 2 + 1 / fact 3 + 1 / fact 4"
    by (simp add: sum.lessThan_Suc eval_nat_numeral)
  then show ?thesis by (simp add: fact_numeral)
qed

(* e 的上下界与指数函数的函数方程。 *)

lemma exp_one_gt_one: "(1::real) < exp 1"
  by (rule one_less_exp_iff [THEN iffD2]) simp

lemma exp_one_le_three: "exp 1 \<le> (3::real)"
  using exp_bound [of 1] by (simp add: field_simps)

lemma exp_add_law:
  fixes x y :: real
  shows "exp (x + y) = exp x * exp y"
  by (rule exp_add)

lemma exp_neg_law:
  fixes x :: real
  shows "exp (-x) = 1 / exp x"
  by (simp add: exp_minus')

(* 尾差估计所需的阶乘—几何不等式。
   k ≥ 1 时 (m+k)! ≥ k! · k^m：k 之后的每个因子都不小于 k。 *)
lemma fact_geometric_bound:
  "1 \<le> k \<Longrightarrow> fact k * k ^ m \<le> fact (m + k)"
proof (induct m)
  case 0 then show ?case by simp
next
  case (Suc m)
  have "fact k * k ^ Suc m = (fact k * k ^ m) * k"
    by (simp add: power_Suc ac_simps)
  also have "... \<le> fact (m + k) * k"
    using Suc by (intro mult_right_mono) simp_all
  have hle: "k \<le> Suc (m + k)" by simp
  also have "... \<le> fact (m + k) * Suc (m + k)"
    by (intro mult_left_mono hle) simp
  also have "fact (m + k) * Suc (m + k) = fact (Suc (m + k))"
    by (simp add: fact_Suc ac_simps)
  finally show ?case by (simp add: add_Suc)
qed

(* 逐项界：1/(m+k)! <= (1/k!) · (1/k)^m。 *)
lemma exp_tail_term_bound:
  fixes k m :: nat
  assumes "1 \<le> k"
  shows "(1::real) / fact (m + k) \<le> (1 / fact k) * ((1 / real k) ^ m)"
proof -
  have hnat: "fact k * k ^ m \<le> fact (m + k)"
    using fact_geometric_bound [OF assms] .
  have hconv: "fact k * real k ^ m = real (fact k * k ^ m)"
    by (simp add: of_nat_fact [symmetric] of_nat_power of_nat_mult [symmetric])
  have hreal: "(fact k * real k ^ m) \<le> fact (m + k)"
    by (simp add: hconv of_nat_fact [symmetric] of_nat_le_iff hnat)
  have hpos: "(0::real) < fact k * real k ^ m" by simp
  have "(1::real) / fact (m + k) = inverse (fact (m + k))"
    by (simp add: divide_inverse)
  also have "... \<le> inverse (fact k * real k ^ m)"
    by (rule le_imp_inverse_le [OF hpos hreal])
  also have "... = (1 / fact k) * ((1 / real k) ^ m)"
    by (simp add: field_simps)
  finally show ?thesis .
qed

(* e 不是有理数（Fourier 证明）。 *)
theorem exp_one_not_rat: "exp 1 \<notin> \<rat>"
proof
  assume h_rat: "exp 1 \<in> \<rat>"
  then obtain m N :: nat where hN: "N \<noteq> 0"
    and hrat: "\<bar>exp 1\<bar> = real m / real N"
    and "coprime m N"
    by (erule Rats_abs_nat_div_natE)
  have hN1: "1 \<le> N" using hN by simp
  have he_pos: "0 < exp 1" using exp_one_gt_one by linarith
  have hrat2: "exp 1 = real m / real N"
    using hrat by (simp add: abs_of_pos he_pos)

  define S where "S = (\<Sum>i\<in>{..N}. (1::real) / fact i)"

  (* (a) N! · e 是整数：N! · (m/N) = m · (N-1)!。 *)
  have h_e_int: "fact N * exp 1 \<in> \<int>"
  proof -
    have hfr: "fact N = real N * fact (N - 1)"
      using hN1 by (simp add: fact_reduce)
    have "fact N * exp 1 = real m * fact (N - 1)"
      by (simp add: hfr hrat2 field_simps hN)
    then show ?thesis by simp
  qed

  (* (b) N! · S 是整数：i <= N 时 i! 整除 N!，故 N!/i! 是自然数。 *)
  have h_term_int: "\<forall>i \<in> {..N}. (fact N :: real) * (1 / fact i) \<in> \<int>"
  proof
    fix i assume "i \<in> {..N}"
    then have hi: "i \<le> N" by simp
    have "fact i * fact (N - i) dvd fact N" by (rule choose_dvd [OF hi])
    then have hd: "fact i dvd fact N"
    proof -
      have "fact i dvd fact i * fact (N - i)" by simp
      also have "fact i * fact (N - i) dvd fact N" by (rule choose_dvd [OF hi])
      finally show ?thesis .
    qed
    obtain c :: nat where hc: "fact N = fact i * c"
      using hd by (elim dvdE)
    have "(fact N :: real) * (1 / fact i) = real c"
      by (simp add: hc field_simps)
    then show "(fact N :: real) * (1 / fact i) \<in> \<int>" by simp
  qed
  have h_S_int: "fact N * S \<in> \<int>"
  proof -
    have "fact N * S = (\<Sum>i\<in>{..N}. fact N * ((1::real) / fact i))"
      by (simp add: S_def sum_distrib_left)
    then show ?thesis by (intro Ints_sum h_term_int)
  qed

  (* (c) 差 k 定义为 N! · (e - S)，它是整数。 *)
  have h_diff_int: "fact N * (exp 1 - S) \<in> \<int>"
  proof -
    have "fact N * (exp 1 - S) = fact N * exp 1 - fact N * S"
      by (simp add: ring_distribs)
    then show ?thesis by (simp add: h_e_int h_S_int)
  qed

  (* (d) 差严格为正：S 是正项级数的真部分和。 *)
  have hsumm: "summable (\<lambda>n. (1::real) / fact n)"
    by (rule exp_one_sums [THEN sums_summable])
  have hsum_inf: "suminf (\<lambda>n. (1::real) / fact n) = exp 1"
    by (rule sums_unique [symmetric]) (rule exp_one_sums)
  have h_part_lt: "(\<Sum>i<Suc N. (1::real) / fact i) < suminf (\<lambda>n. (1::real) / fact n)"
    by (rule sum_less_suminf [OF hsumm]) simp_all
  have hS_lt: "S < exp 1"
    using h_part_lt by (simp add: S_def hsum_inf)
  have h_pos: "0 < fact N * (exp 1 - S)"
    by (intro mult_pos_pos fact_gt_zero) linarith

  (* (e) 尾差上界。令 k = N+1，T = sum_m 1/(m+k)! = e - S。
         拆出首项 1/k!，对剩余级数与公比 1/k 的几何级数比较。 *)
  define k where "k = Suc N"
  have hk1: "1 \<le> k" and hk2: "2 \<le> k" using hN1 by (simp_all add: k_def)
  have hkn: "real k \<noteq> 0" using hk2 by simp
  define T where "T = suminf (\<lambda>m. (1::real) / fact (m + k))"
  have hT_summ: "summable (\<lambda>m. (1::real) / fact (m + k))"
    by (rule summable_ignore_initial_segment [OF hsumm])
  have hT_eq: "T = exp 1 - S"
    unfolding T_def S_def
    by (simp add: suminf_minus_initial_segment [OF hsumm, of k] k_def hsum_inf)

  have hsplit: "T = 1 / fact k + suminf (\<lambda>j. (1::real) / fact (j + Suc k))"
  proof -
    have h: "suminf (\<lambda>j. (1::real) / fact (Suc j + k)) = T - 1 / fact k"
      by (rule suminf_split_head [OF hT_summ])
    have heq: "(\<lambda>j. (1::real) / fact (Suc j + k)) =
        (\<lambda>j. (1::real) / fact (j + Suc k))"
      by (simp add: fun_eq_iff add_Suc)
    show ?thesis using h [unfolded heq] by (simp add: T_def) linarith
  qed

  have hs2: "summable (\<lambda>j. (1::real) / fact (j + Suc k))"
    by (rule summable_ignore_initial_segment [OF hT_summ])
  have hg_sums: "(\<lambda>j. ((1::real) / real (Suc k)) ^ j) sums
      1 / (1 - (1 / real (Suc k)))"
    by (rule geometric_sums) simp
  have hg_summ: "summable (\<lambda>j. ((1::real) / real (Suc k)) ^ j)"
    by (rule hg_sums [THEN sums_summable])
  have hg_val: "suminf (\<lambda>j. ((1::real) / real (Suc k)) ^ j) =
      real (Suc k) / real k"
  proof -
    have "suminf (\<lambda>j. ((1::real) / real (Suc k)) ^ j) =
        1 / (1 - (1 / real (Suc k)))"
      by (rule sums_unique [symmetric]) (rule hg_sums)
    also have "... = real (Suc k) / real k"
      using hkn by (simp add: field_simps)
    finally show ?thesis .
  qed

  define g where "g = \<lambda>j. (1 / fact (Suc k) :: real) * ((1 / real (Suc k)) ^ j)"
  have hg2_summ: "summable g"
    by (simp add: g_def; rule summable_mult [OF hg_summ])
  have hle2: "suminf (\<lambda>j. (1::real) / fact (j + Suc k)) \<le> suminf g"
  proof (rule suminf_le)
    show "\<forall>j. (1::real) / fact (j + Suc k) \<le> g j"
      by (auto simp: g_def intro: exp_tail_term_bound)
  next show "summable (\<lambda>j. (1::real) / fact (j + Suc k))" by (rule hs2)
  next show "summable g" by (rule hg2_summ)
  qed
  have h_g_val: "suminf g = (1 / fact (Suc k)) * (real (Suc k) / real k)"
    by (simp add: g_def suminf_mult [OF hg_summ] hg_val)

  have hTail: "exp 1 - S \<le> (real k + 1) / (fact k * real k)"
  proof -
    have h1: "T \<le> 1 / fact k + (1 / fact (Suc k)) * (real (Suc k) / real k)"
      using hsplit hle2 h_g_val by linarith
    have h2: "1 / fact k + (1 / fact (Suc k)) * (real (Suc k) / real k) =
        (real k + 1) / (fact k * real k)"
      using hkn by (simp add: fact_Suc field_simps)
    with hT_eq show ?thesis by linarith
  qed

  (* (f) 乘以 N! 后严格小于 1：N! · (k+1)/(k! · k) = (k+1)/k^2，而 k ≥ 2 时 k+1 < k^2。 *)
  have h_sq: "\<forall>n. Suc n + 2 < (Suc n + 1) ^ 2"
    by (induct n) simp_all
  have hN2: "N + 2 < (N + 1) ^ 2"
    using hN1 h_sq [of "N - 1"] by (cases N) auto
  have h7: "real k + 1 < real k ^ 2"
  proof -
    have h: "real (N + 2) < real ((N + 1) ^ 2)"
      by (simp add: of_nat_less_iff hN2)
    then show ?thesis by (simp add: k_def)
  qed
  have h4: "fact N * (exp 1 - S) \<le>
      fact N * ((real k + 1) / (fact k * real k))"
    by (intro mult_left_mono hTail) simp
  have h5: "fact N * ((real k + 1) / (fact k * real k)) =
      (real k + 1) / real k ^ 2"
    using hkn by (simp add: k_def fact_Suc field_simps)
  have h6: "(real k + 1) / real k ^ 2 < 1"
    using h7 by simp
  have hfin: "fact N * (exp 1 - S) < 1"
    using h4 h5 h6 by linarith

  (* (g) 整数严格介于 0 和 1 之间，矛盾。 *)
  obtain j :: int where hj: "fact N * (exp 1 - S) = of_int j"
    using h_diff_int by (elim Ints_cases)
  have h_j_pos: "0 < j"
    by (rule of_int_less_iff [THEN iffD1]) (simp add: hj; linarith)
  have h_j_lt: "j < 1"
    by (rule of_int_less_iff [THEN iffD1]) (simp add: hj; linarith)
  then show False using h_j_pos by presburger
qed

end
