theory FieldAxioms
  imports "HOL-Analysis.Analysis"
begin

(* 第 04 章 实数域（上）：Isabelle/HOL 通道。
   域公理的推论与有序域性质。注意 Isabelle2026 没有 norm_num 方法，
   数值等式用 simp/field_simps。 *)

(* Z 不是域：2 没有整数乘法逆元。 *)
lemma int_not_field: "\<not> (\<exists>z::int. 2 * z = 1)"
  by presburger

(* 只用域公理就能证明的基本事实。 *)
lemma "0 * (x::real) = 0" by simp
lemma "(-1) * (x::real) = -x" by simp
lemma "-(-(x::real)) = x" by simp

(* 乘法逆的唯一性：xy = 1 蕴含 y = 1/x。 *)
lemma inv_unique:
  fixes x y :: real
  assumes "x \<noteq> 0" and "x * y = 1"
  shows "y = 1 / x"
proof -
  have "y = (x * y) / x" using assms(1) by (simp add: field_simps)
  also have "... = 1 / x" using assms(2) by simp
  finally show ?thesis .
qed

(* 有序域公理 O2 的推论：平方非负、0 < 1。 *)
lemma "0 \<le> (x::real)^2" by simp
lemma "(0::real) < 1" by simp

(* 原书列举的有序域性质：正数保序与取倒数反序。 *)
lemma pos_mult_mono:
  fixes x y z :: real
  assumes "0 < x" and "y < z"
  shows "x * y < x * z"
  using assms by (simp add: mult_less_cancel_left_pos)

lemma inv_antitone:
  fixes x y :: real
  assumes "0 < x" and "x < y"
  shows "1 / y < 1 / x"
  using assms by (simp add: frac_less2)

(* 中点严格落在两数之间。 *)
lemma midpoint_between:
  fixes a b :: real
  assumes "a < b"
  shows "a < (a+b)/2 \<and> (a+b)/2 < b"
  using assms by auto

(* 例 5.2 的加法与乘法公式。分母非零时 field_simps 直接通分。 *)
lemma rat_add_formula:
  fixes a b c d :: int
  assumes "b \<noteq> 0" "d \<noteq> 0"
  shows "(of_int a / of_int b + of_int c / of_int d :: rat)
       = of_int (a * d + b * c) / of_int (b * d)"
  using assms by (simp add: field_simps)

lemma rat_mul_formula:
  fixes a b c d :: int
  assumes "b \<noteq> 0" "d \<noteq> 0"
  shows "((of_int a / of_int b) * (of_int c / of_int d) :: rat)
       = of_int (a * c) / of_int (b * d)"
  using assms by (simp add: field_simps)

(* 编者注：整数乘法可逆当且仅当该整数是 ±1。 *)
lemma int_units: "(\<exists>w::int. z * w = 1) \<longleftrightarrow> (z = 1 \<or> z = -1)"
  by (auto simp: zmult_eq_1_iff)

(* 每个有理数都是整数之比：封闭性验证的原子步骤（原书例 5.2）。 *)
lemma rat_quotient:
  fixes r :: rat
  shows "\<exists>a b::int. b \<noteq> 0 \<and> r = of_int a / of_int b"
proof -
  obtain a b where qe: "quotient_of r = (a, b)" by (cases "quotient_of r") auto
  have hb: "0 < b" using quotient_of_denom_pos[OF qe] .
  have hr: "r = of_int a / of_int b" using quotient_of_div[OF qe] .
  have "b \<noteq> 0" using hb by simp
  with hr show ?thesis by blast
qed

end
