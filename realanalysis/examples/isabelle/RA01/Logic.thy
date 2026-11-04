theory Logic
  imports "HOL-Analysis.Analysis"
begin

(* 第 01 章 数学语言与证明技巧：Isabelle/HOL 通道。
   HOL 默认经典逻辑，命题层面的德摩根律与逆否命题由 blast 直接闭合。
   源码约定：数学符号一律用 Isabelle 实体写法（如 \<forall>、\<longrightarrow>）。 *)

(* 逆否命题与原命题等价。 *)
lemma contrapositive_iff: "(A \<longrightarrow> B) \<longleftrightarrow> (\<not> B \<longrightarrow> \<not> A)"
  by blast

(* 量词的德摩根律。 *)
lemma not_forall_iff: "(\<not> (\<forall>x. P x)) \<longleftrightarrow> (\<exists>x. \<not> P x)"
  by blast

lemma not_exists_iff: "(\<not> (\<exists>x. P x)) \<longleftrightarrow> (\<forall>x. \<not> P x)"
  by blast

(* 量词顺序之一（真）：每个实数 x 都有 y > x，取 y = x+1。 *)
lemma forall_exists_order: "\<forall>(x::real). \<exists>y. y > x"
  by (metis less_add_one)

(* 量词顺序之二（假）：不存在压过所有实数的 y。 *)
lemma no_universal_upper_bound: "\<not> (\<exists>(y::real). \<forall>x. y > x)"
proof
  assume "\<exists>y. \<forall>x. y > (x::real)"
  then obtain y where "\<forall>x. y > (x::real)" by auto
  then have "y > y + 1" by auto
  then show False by simp
qed

(* 原书例 2.4：先证无除法版本 2 * (1+...+n) = n(n+1)。
   归纳步把 {1..n+1} 拆成 {1..n} 加末项，代数整理由 algebra_simps 完成。 *)
lemma sum_double:
  fixes n :: nat
  shows "2 * (\<Sum>i\<in>{1..n}. i) = n*(n+1)"
proof (induction n)
  case 0
  show ?case by simp
next
  case (Suc n)
  have "{1..Suc n} = insert (Suc n) {1..n}" by auto
  then show ?case using Suc.IH by (simp add: algebra_simps)
qed

(* 取一半得到原书公式：(2*S) div 2 = S 由 simp 的 div_mult_self 规则完成。 *)
lemma sum_formula:
  fixes n :: nat
  shows "(\<Sum>i\<in>{1..n}. i) = n*(n+1) div 2"
proof -
  have h: "2 * (\<Sum>i\<in>{1..n}. i) = n*(n+1)" by (rule sum_double)
  have "n*(n+1) div 2 = (2 * (\<Sum>i\<in>{1..n}. i)) div 2" using h by simp
  also have "(2 * (\<Sum>i\<in>{1..n}. i)) div 2 = (\<Sum>i\<in>{1..n}. i)" by simp
  finally have "n*(n+1) div 2 = (\<Sum>i\<in>{1..n}. i)" .
  then show ?thesis by simp
qed

(* 原书例 2.5：lim_{x->2} (3x+1) = 7 的 eps-delta 直接证明，delta = eps/3。
   Isar 结构化证明：fix/assume/show 与纸面证明逐行对应。 *)
lemma linear_limit:
  "\<forall>(eps::real). 0 < eps \<longrightarrow>
     (\<exists>delta. 0 < delta \<and> (\<forall>x. \<bar>x - 2\<bar> < delta \<longrightarrow> \<bar>(3*x+1) - 7\<bar> < eps))"
proof (intro allI impI)
  fix eps :: real
  assume heps: "0 < eps"
  show "\<exists>delta. 0 < delta \<and> (\<forall>x. \<bar>x - 2\<bar> < delta \<longrightarrow> \<bar>(3*x+1) - 7\<bar> < eps)"
  proof (rule exI [where x = "eps/3"], intro conjI allI impI)
    show "0 < eps/3" using heps by simp
  next
    fix x
    assume hx: "\<bar>x - 2\<bar> < eps/3"
    have eq2: "\<bar>(3*x+1) - 7\<bar> = 3*\<bar>x-2\<bar>"
    proof -
      have "\<bar>(3*x+1) - 7\<bar> = \<bar>3*(x-2)\<bar>" by (simp add: algebra_simps)
      also have "\<bar>3*(x-2)\<bar> = \<bar>3\<bar> * \<bar>x-2\<bar>" by (rule abs_mult)
      also have "\<bar>3\<bar> * \<bar>x-2\<bar> = 3 * \<bar>x-2\<bar>" by simp
      finally show ?thesis .
    qed
    have lt: "3*\<bar>x-2\<bar> < eps"
    proof -
      have "3*\<bar>x-2\<bar> < 3*(eps/3)" by (rule mult_strict_left_mono [OF hx]) simp
      also have "3*(eps/3) = eps" by simp
      finally show ?thesis .
    qed
    show "\<bar>(3*x+1) - 7\<bar> < eps" using eq2 lt by simp
  qed
qed

(* 原书例 2.2：x = y 当且仅当任意 eps>0 都有 |x-y| < eps。
   反向用反证：x \<noteq> y 时取 eps = |x-y| 本身，得 |x-y| < |x-y|。 *)
lemma epsilon_equality:
  "(x::real) = y \<longleftrightarrow> (\<forall>eps>0. \<bar>x-y\<bar> < eps)"
proof
  assume "x = y"
  then show "\<forall>eps>0. \<bar>x-y\<bar> < eps" by simp
next
  assume h: "\<forall>eps>0. \<bar>x-y\<bar> < eps"
  show "x = y"
  proof (rule ccontr)
    assume hne: "x \<noteq> y"
    have hpos: "0 < \<bar>x-y\<bar>" using hne by simp
    have contra: "\<bar>x-y\<bar> < \<bar>x-y\<bar>" using h hpos by blast
    show False using contra by linarith
  qed
qed

end
