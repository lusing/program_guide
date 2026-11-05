theory Completeness
  imports "HOL-Analysis.Analysis"
begin

(* 第 05 章 实数域（下）：完备性的三大推论 + 补洞终章。
   Isabelle 的 real 是条件完备格，Sup 由完备性给出。 *)

(* 定理 5.5（Archimedean 性质）：正数的自然数倍可以超过任何实数。 *)
lemma archimedean_mul:
  fixes x y :: real
  assumes "0 < x"
  shows "\<exists>n::nat. y < real n * x"
proof -
  obtain n where "y / x < real n" using reals_Archimedean2 by blast
  then have "y < real n * x" using assms by (simp add: pos_divide_less_eq)
  then show ?thesis by auto
qed

(* 定理 5.6（有理数稠密）：任何两个实数之间都有有理数。 *)
lemma rat_dense:
  fixes a b :: real
  assumes "a < b"
  shows "\<exists>q::rat. a < of_rat q \<and> of_rat q < b"
proof -
  from Rats_dense_in_real [OF assms] obtain r
    where "r \<in> \<rat>" "a < r" "r < b" by auto
  then obtain q :: rat where "r = of_rat q"
    using Rats_cases by blast
  then show ?thesis using \<open>a < r\<close> \<open>r < b\<close> by auto
qed

(* 定理 5.8（根的存在性，平方根版）。 *)
lemma sqrt_two_exists: "\<exists>y::real. 0 < y \<and> y^2 = 2"
proof (intro exI[of _ "sqrt 2"] conjI)
  show "0 < sqrt 2" by simp
  show "(sqrt 2)^2 = 2" by simp
qed

(* 本章核心：{0 \<le> x, x^2 < 2} 的上确界恰好是 sqrt 2。
   上界性：x^2 < 2 且 x \<ge> 0 蕴含 x \<le> sqrt 2（否则平方超过 2）。
   最小性：b < sqrt 2 时，b < 0 被元素 0 超过；0 \<le> b 时被中点超过。 *)
lemma sqrt2_is_sup: "Sup {x::real. 0 \<le> x \<and> x^2 < 2} = sqrt 2"
proof (rule order.antisym)
  have ne: "{x::real. 0 \<le> x \<and> x^2 < 2} \<noteq> {}"
  proof -
    have "(0::real) \<in> {x::real. 0 \<le> x \<and> x^2 < 2}" by simp
    then show ?thesis by blast
  qed
  have bd: "bdd_above {x::real. 0 \<le> x \<and> x^2 < 2}"
  proof (rule bdd_aboveI[of _ 2])
    fix x assume "x \<in> {x::real. 0 \<le> x \<and> x^2 < 2}"
    then have hx0: "0 \<le> x" and hx2: "x^2 < 2" by auto
    show "x \<le> 2"
    proof (rule ccontr)
      assume "\<not> x \<le> 2"
      then have "2 < x" by simp
      then have "2^2 < x^2" by (rule power_strict_mono) simp_all
      with hx2 show False by simp
    qed
  qed
  show "Sup {x::real. 0 \<le> x \<and> x^2 < 2} \<le> sqrt 2"
  proof (rule cSup_least[OF ne])
    fix x assume "x \<in> {x::real. 0 \<le> x \<and> x^2 < 2}"
    then have hx0: "0 \<le> x" and hx2: "x^2 < 2" by auto
    show "x \<le> sqrt 2"
    proof (rule ccontr)
      assume "\<not> x \<le> sqrt 2"
      then have "sqrt 2 < x" by simp
      then have "(sqrt 2)^2 < x^2" by (rule power_strict_mono) simp_all
      then have "2 < x^2" by simp
      with hx2 show False by simp
    qed
  qed
  show "sqrt 2 \<le> Sup {x::real. 0 \<le> x \<and> x^2 < 2}"
  proof (rule ccontr)
    assume "\<not> sqrt 2 \<le> Sup {x::real. 0 \<le> x \<and> x^2 < 2}"
    then have hs: "Sup {x::real. 0 \<le> x \<and> x^2 < 2} < sqrt 2" by simp
    have hnn: "0 \<le> Sup {x::real. 0 \<le> x \<and> x^2 < 2}"
      by (rule cSup_upper[OF _ bd]) simp
    (* 把 Sup 项与 sqrt 2 各起一个名字，linarith 才把它们当原子处理。 *)
    obtain s where s_def: "s = Sup {x::real. 0 \<le> x \<and> x^2 < 2}" by blast
    obtain r where r_def: "r = sqrt (2::real)" by blast
    define m where "m = (s + r) / 2"
    have hs': "s < r" using hs s_def r_def by simp
    have hnn': "0 \<le> s" using hnn s_def by simp
    (* 中点严格夹在 s 与 r 之间：库引理 field_less_half_sum / gt_half_sum。 *)
    have hsm': "s < m" unfolding m_def by (rule field_less_half_sum[OF hs'])
    have hms': "m < r"
    proof -
      have "(s + r) / (1 + 1) < r" by (rule gt_half_sum[OF hs'])
      then show ?thesis unfolding m_def by simp
    qed
    have hm0: "0 \<le> m" using hnn' hsm' by simp
    have hsm: "Sup {x::real. 0 \<le> x \<and> x^2 < 2} < m" using hsm' s_def by simp
    have hms: "m < sqrt 2" using hms' r_def by simp
    have hm2: "m^2 < 2"
    proof -
      have "m^2 < (sqrt 2)^2" using hms hm0 by (rule power_strict_mono) simp
      then show ?thesis by simp
    qed
    have hm_mem: "m \<in> {x::real. 0 \<le> x \<and> x^2 < 2}" using hm0 hm2 by simp
    have "m \<le> Sup {x::real. 0 \<le> x \<and> x^2 < 2}"
      by (rule cSup_upper[OF hm_mem bd])
    with hsm show False by simp
  qed
qed

end
