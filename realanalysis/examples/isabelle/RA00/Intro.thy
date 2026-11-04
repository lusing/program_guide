theory Intro
  imports "HOL-Analysis.Analysis"
begin

(* 第 00 章 导言：精确的实数世界。Isabelle 的 real 是公理化的
   数学实数（Cauchy 序列的商类型），所有等式都是精确的，
   不存在浮点舍入。注意 Isabelle2026 的 Main 不含 real，
   需要 Complex_Main 或 Analysis 级别的导入。 *)

lemma "(2::real) + 2 = 4"
  by simp

lemma "(1::real)/3 + 1/3 + 1/3 = 1"
  by (simp add: field_simps)

(* 根式是精确对象：sqrt 2 的平方严格等于 2。
   real_sqrt_mult_self 是 simp 规则：sqrt a * sqrt a = |a|。 *)
lemma "sqrt 2 * sqrt 2 = (2::real)"
  by simp

(* Archimedean 性质预览：任意实数都有自然数超过它。
   reals_Archimedean2 : \<exists>n. x < of_nat n（archimedean_field 上）。 *)
lemma archimedean_teaser: "\<forall>(x::real). \<exists>n::nat. x < real n"
  using reals_Archimedean2 by blast

(* 单位分数可以任意小：对任意 eps>0 存在 n 使 1/(n+1) < eps。
   这是第 02 章区间族并集证明的关键工具。 *)
lemma one_div_teaser:
  fixes eps :: real
  assumes "0 < eps"
  shows "\<exists>n::nat. 1 / (1 + real n) < eps"
proof -
  from reals_Archimedean [OF assms] obtain n
    where "inverse (of_nat (Suc n)) < eps" by auto
  then have "1 / (1 + real n) < eps"
    by (simp add: inverse_eq_divide)
  then show ?thesis by auto
qed

(* 数学实数与机器浮点的对照：float 上 0.1 + 0.2 并不等于 0.3。
   取消下一行注释可在 PIDE 中求值观察误差。 *)
(* value "(0.1::float) + 0.2" *)

end
