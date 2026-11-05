theory ComplexEuclidean
  imports "HOL-Analysis.Analysis"
begin

(* 第 06 章 复数与欧几里得空间：Isabelle 通道。
   complex 是实部虚部的 codatatype；real^2 是有限笛卡尔积（vec），
   其上 inner/norm 由 Finite_Cartesian_Product 实例给出。 *)

(* ---------------- 6.1 复数：实部与虚部 ---------------- *)

(* 复数由实部与虚部唯一确定。 *)
lemma complex_parts: "Complex (Re z) (Im z) = z"
  by (rule complex_surj)

(* i^2 = -1。 *)
lemma i_sq: "\<i>\<^sup>2 = -1"
  by simp

(* i 的实部为 0、虚部为 1：它不是实数。 *)
lemma i_im: "Im \<i> = 1"
  by simp

(* 乘法公式：(a+bi)(c+di) = (ac-bd) + (ad+bc)i。
   用 complex_eq_iff 拆成实部与虚部两条，再由 simp 展开乘法分量。 *)
lemma complex_mul_formula:
  fixes a b c d :: real
  shows "(complex_of_real a + complex_of_real b * \<i>) *
         (complex_of_real c + complex_of_real d * \<i>)
       = complex_of_real (a * c - b * d) + complex_of_real (a * d + b * c) * \<i>"
  by (simp add: complex_eq_iff)

(* ---------------- 6.2 共轭与模 ---------------- *)

(* i 的共轭是 -i。 *)
lemma cnj_i: "cnj \<i> = - \<i>"
  by (simp add: complex_eq_iff)

(* z * cnj z = of_real((norm z)^2)：共轭乘积给出模平方。 *)
lemma conj_norm_sq: "z * cnj z = complex_of_real ((norm z)\<^sup>2)"
  using complex_norm_square [of z] by simp

(* i 的模是 1（单位圆上的点）。 *)
lemma norm_i: "norm \<i> = 1"
  by simp

(* 勾股例子：3 + 4i 的模是 5。norm_complex_def 给出
   norm z = sqrt((Re z)^2 + (Im z)^2)，代入即 sqrt(9+16) = 5。 *)
lemma norm_3_4i:
  "norm (complex_of_real 3 + 4 * \<i>) = 5"
  by (simp add: norm_complex_def)

(* ---------------- 6.3 欧几里得空间 R^2 ---------------- *)

type_synonym R2 = "real^2"

definition xv :: R2 where "xv = (\<chi> i. if i = 1 then 1 else 2)"
definition yv :: R2 where "yv = (\<chi> i. if i = 1 then 3 else 4)"

(* 内积的坐标公式：对应分量相乘再在有限指标集 UNIV 上求和。
   注意裸写法 (\<Sum>i. ...) 会被解析成无限级数 suminf，
   有限求和必须显式给出集合 UNIV。 *)
lemma inner_coord:
  "inner (x::R2) y = (\<Sum>i\<in>(UNIV::2 set). x$i * y$i)"
  by (simp add: inner_vec_def)

(* 范数平方的坐标公式：各分量平方和。
   power2_norm_eq_inner 是单向 simp 规则（norm^2 -> inner），
   所以先把 norm^2 换成 inner，再展开 inner_vec_def。 *)
lemma norm_sq_coord:
  "(norm (x::R2))\<^sup>2 = (\<Sum>i\<in>(UNIV::2 set). (x$i)^2)"
proof -
  have "(norm x)\<^sup>2 = inner x x" by (simp add: power2_norm_eq_inner)
  also have "inner x x = (\<Sum>i\<in>(UNIV::2 set). (x$i)^2)"
    by (simp add: inner_vec_def power2_eq_square)
  finally show ?thesis .
qed

(* 具体数值：inner xv yv = 1*3 + 2*4 = 11。 *)
lemma inner_xy: "inner xv yv = 11"
  by (simp add: inner_vec_def xv_def yv_def sum_2)

(* 范数平方：norm xv ^2 = 5，norm yv ^2 = 25。 *)
lemma norm_x_sq: "(norm xv)\<^sup>2 = 5"
proof -
  have "(norm xv)\<^sup>2 = inner xv xv" by (simp add: power2_norm_eq_inner)
  also have "inner xv xv = 5" by (simp add: inner_vec_def xv_def sum_2)
  finally show ?thesis .
qed

lemma norm_y_sq: "(norm yv)\<^sup>2 = 25"
proof -
  have "(norm yv)\<^sup>2 = inner yv yv" by (simp add: power2_norm_eq_inner)
  also have "inner yv yv = 25" by (simp add: inner_vec_def yv_def sum_2)
  finally show ?thesis .
qed

(* ---------------- 6.4 Cauchy–Schwarz ---------------- *)

(* 一般形式：内积平方 <= 两个范数平方之积。 *)
lemma cs_general:
  fixes u v :: "real^5"
  shows "(inner u v)\<^sup>2 \<le> (norm u)\<^sup>2 * (norm v)\<^sup>2"
  by (simp add: Cauchy_Schwarz_ineq power2_norm_eq_inner)

(* 绝对值形式：|inner u v| <= norm u * norm v。 *)
lemma cs_abs:
  fixes u v :: R2
  shows "\<bar>inner u v\<bar> \<le> norm u * norm v"
  by (rule Cauchy_Schwarz_ineq2)

(* 在 xv, yv 上核对：121 <= 125。 *)
lemma cs_check: "(inner xv yv)\<^sup>2 \<le> (norm xv)\<^sup>2 * (norm yv)\<^sup>2"
  by (simp add: inner_xy norm_x_sq norm_y_sq)

(* Lagrange 恒等式（二维）：(ad-bc)^2 = norm x ^2 * norm y ^2 - (inner x y)^2。
   这里 4 = 125 - 121：C-S 的"缺口"恰好是一个平方。 *)
lemma lagrange_gap:
  "(1 * 4 - 2 * 3 :: real)^2 = (norm xv)\<^sup>2 * (norm yv)\<^sup>2 - (inner xv yv)\<^sup>2"
  by (simp add: inner_xy norm_x_sq norm_y_sq)

(* 三角不等式：C-S 的直接推论。 *)
lemma triangle_ineq:
  fixes u v :: R2
  shows "norm (u + v) \<le> norm u + norm v"
  by (rule norm_triangle_ineq)

end
