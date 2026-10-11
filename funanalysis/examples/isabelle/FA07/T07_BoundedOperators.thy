theory T07_BoundedOperators
  imports "HOL-Analysis.Cartesian_Euclidean_Space"
begin

text \<open>
  第 07 章（Isabelle 通道）：B(ℋ) 是赋范代数（Conway II.1）。
  1. 复合的次乘性 onorm (f∘g) ≤ onorm f * onorm g（Conway 1.2 (c)）；
  2. 对角缩放 diag2 的算子范数 = max|d|（Conway 1.5 有限维化身）。
  计算全部走 axis 分解（FA00 风格），避开 UNIV 坐标枚举。
\<close>

section \<open>复合的次乘性（Conway 1.2 (c)）\<close>

lemma fa_onorm_comp_le:
  fixes g :: "'a::{real_normed_vector, perfect_space} \<Rightarrow> 'b::{real_normed_vector, perfect_space}"
    and f :: "'b::{real_normed_vector, perfect_space} \<Rightarrow> 'c::real_normed_vector"
  assumes fg: "bounded_linear f" and gg: "bounded_linear g"
  shows "onorm (f \<circ> g) \<le> onorm f * onorm g"
proof -
  have hnn: "0 \<le> onorm f * onorm g"
    by (rule mult_nonneg_nonneg [OF onorm_pos_le [OF fg] onorm_pos_le [OF gg]])
  have hall: "norm ((f \<circ> g) x) \<le> onorm f * onorm g * norm x" for x
  proof -
    have "norm ((f \<circ> g) x) = norm (f (g x))" by simp
    also have "\<dots> \<le> onorm f * norm (g x)" by (rule onorm [OF fg])
    also have "\<dots> \<le> onorm f * (onorm g * norm x)"
      by (rule mult_left_mono [OF onorm [OF gg] onorm_pos_le [OF fg]])
    also have "\<dots> = onorm f * onorm g * norm x" by (simp add: algebra_simps)
    finally show ?thesis .
  qed
  show ?thesis using hnn hall by (rule onorm_bound)
qed

section \<open>对角缩放：有界性与范数（Conway 1.5 有限维版）\<close>

definition diag2 :: "real \<Rightarrow> real \<Rightarrow> real^2 \<Rightarrow> real^2" where
  "diag2 a b x = (a * x $ 1) *\<^sub>R axis 1 1 + (b * x $ 2) *\<^sub>R axis 2 1"

lemma diag2_add: "diag2 a b (x + y) = diag2 a b x + diag2 a b y"
  unfolding diag2_def by (simp add: algebra_simps scaleR_add_right scaleR_add_left)

lemma diag2_scale: "diag2 a b (r *\<^sub>R x) = r *\<^sub>R diag2 a b x"
  unfolding diag2_def by (simp add: algebra_simps)

text \<open>范数平方：勾股分解（两个 axis 方向正交）。\<close>

lemma norm_sq_diag2:
  "norm (diag2 a b x) ^ 2 = (a * x $ 1) ^ 2 + (b * x $ 2) ^ 2"
proof -
  have "norm (diag2 a b x) ^ 2 = inner (diag2 a b x) (diag2 a b x)"
    by (simp add: power2_norm_eq_inner)
  also have "\<dots> = (a * x $ 1) * (a * x $ 1) + (b * x $ 2) * (b * x $ 2)"
    unfolding diag2_def by (simp add: inner_add_left inner_add_right
        inner_scaleR_left inner_scaleR_right inner_axis_axis)
  finally show ?thesis by (simp add: power2_eq_square)
qed

lemma norm_diag2_le:
  "norm (diag2 a b x) \<le> max (abs a) (abs b) * norm x"
proof -
  have hnx: "norm x ^ 2 = (x $ 1) * (x $ 1) + (x $ 2) * (x $ 2)"
    by (simp add: power2_norm_eq_inner inner_vec_def sum_2)
  have ha2: "(abs a) ^ 2 \<le> (max (abs a) (abs b)) ^ 2"
    by (rule power_mono) simp_all
  have hb2: "(abs b) ^ 2 \<le> (max (abs a) (abs b)) ^ 2"
    by (rule power_mono) simp_all
  have h0: "(a * x $ 1) ^ 2 \<le> (max (abs a) (abs b)) ^ 2 * (x $ 1) ^ 2"
  proof -
    have eq: "(a * x $ 1) ^ 2 = (abs a) ^ 2 * (x $ 1) ^ 2"
      by (simp add: abs_mult power_mult_distrib)
    show ?thesis unfolding eq
      by (rule mult_right_mono [OF ha2]) simp
  qed
  have h1: "(b * x $ 2) ^ 2 \<le> (max (abs a) (abs b)) ^ 2 * (x $ 2) ^ 2"
  proof -
    have eq: "(b * x $ 2) ^ 2 = (abs b) ^ 2 * (x $ 2) ^ 2"
      by (simp add: abs_mult power_mult_distrib)
    show ?thesis unfolding eq
      by (rule mult_right_mono [OF hb2]) simp
  qed
  have hle: "norm (diag2 a b x) ^ 2
      \<le> (max (abs a) (abs b)) ^ 2 * ((x $ 1) ^ 2 + (x $ 2) ^ 2)"
    unfolding norm_sq_diag2 using add_mono [OF h0 h1] by (simp add: algebra_simps)
  have hnn: "(0::real) \<le> max (abs a) (abs b) * norm x"
    by (simp add: mult_nonneg_nonneg)
  show ?thesis
  proof (rule power2_le_imp_le)
    show "(0::real) \<le> max (abs a) (abs b) * norm x" by (rule hnn)
    have hnxS : "norm x * norm x = (x $ 1) * (x $ 1) + (x $ 2) * (x $ 2)"
      by (rule hnx [unfolded power2_eq_square])
    have hnx' : "(norm x) ^ 2 = (x $ 1) ^ 2 + (x $ 2) ^ 2"
      by (unfold power2_eq_square) (rule hnxS)
    have hR: "(max (abs a) (abs b) * norm x) ^ 2
        = (max (abs a) (abs b)) ^ 2 * ((x $ 1) ^ 2 + (x $ 2) ^ 2)"
    proof -
      have e1: "(max (abs a) (abs b) * norm x) ^ 2
          = (max (abs a) (abs b)) ^ 2 * (norm x) ^ 2"
        by (simp add: power_mult_distrib)
      show ?thesis using e1 hnx' by simp
    qed
    show "norm (diag2 a b x) ^ 2 \<le> (max (abs a) (abs b) * norm x) ^ 2"
      unfolding hR by (rule hle)
  qed
qed

lemma bounded_linear_diag2: "bounded_linear (diag2 a b)"
proof (rule bounded_linear_intro [where K = "max (abs a) (abs b)"])
  fix x y :: "real^2"
  show "diag2 a b (x + y) = diag2 a b x + diag2 a b y"
    by (rule diag2_add)
next
  fix r :: real and x :: "real^2"
  show "diag2 a b (r *\<^sub>R x) = r *\<^sub>R diag2 a b x"
    by (rule diag2_scale)
next
  fix x :: "real^2"
  have "norm (diag2 a b x) \<le> max (abs a) (abs b) * norm x"
    by (rule norm_diag2_le)
  then show "norm (diag2 a b x) \<le> norm x * max (abs a) (abs b)"
    by (simp add: mult.commute)
qed


end
