theory T04_Riesz
  imports "HOL-Analysis.Cartesian_Euclidean_Space"
begin

text \<open>
  第 04 章（Isabelle 通道）：Riesz 表示定理的有限维化身（Conway I.3.4）。
  一般 Hilbert 空间上的 Riesz 定理由 Lean 通道的 Ch04Riesz.lean 承载；
  这里在 real^2（二维欧氏空间）上把定理"算到底"：每个有界线性泛函都等于
  与固定向量 rep_vec L 的内积，且算子范数恰为该向量的范数。
\<close>

section \<open>表示向量的构造\<close>

definition rep_vec :: "(real^2 \<Rightarrow> real) \<Rightarrow> real^2" where
  "rep_vec L = (\<chi> i. L (axis i 1))"

text \<open>线性泛函沿标准正交基展开后逐项对上内积。\<close>

lemma rep_vec_works:
  fixes L :: "real^2 \<Rightarrow> real"
  assumes "bounded_linear L"
  shows "L y = inner y (rep_vec L)"
proof -
  interpret L: bounded_linear L by fact
  have sumL: "L y = (\<Sum>i\<in>UNIV. (y $ i) * L (axis i 1))"
  proof -
    have h1: "L (\<Sum>i\<in>UNIV. (y $ i) *\<^sub>R (axis i 1 :: real^2))
        = (\<Sum>i\<in>UNIV. (y $ i) * L (axis i 1))"
      by (simp add: L.sum L.scale)
    have h2: "(\<Sum>i\<in>UNIV. (y $ i) *\<^sub>R (axis i 1 :: real^2)) = y"
      using basis_expansion[of y] by (simp add: scalar_mult_eq_scaleR)
    show ?thesis using h1 h2 by simp
  qed
  have sumI: "inner y (rep_vec L) = (\<Sum>i\<in>UNIV. (y $ i) * L (axis i 1))"
    by (simp add: inner_vec_def rep_vec_def)
  show ?thesis
    using sumL sumI by simp
qed

section \<open>范数相等：onorm L = norm (rep_vec L)\<close>

lemma onorm_eq_rep_vec:
  fixes L :: "real^2 \<Rightarrow> real"
  assumes "bounded_linear L"
  shows "onorm L = norm (rep_vec L)"
proof (rule antisym)
  show "onorm L \<le> norm (rep_vec L)"
  proof (rule onorm_le)
    fix x :: "real^2"
    have "norm (L x) = \<bar>inner x (rep_vec L)\<bar>"
      by (simp only: rep_vec_works[OF assms] real_norm_def)
    also have "\<dots> \<le> norm x * norm (rep_vec L)"
      by (rule Cauchy_Schwarz_ineq2)
    finally show "norm (L x) \<le> norm (rep_vec L) * norm x"
      by (simp add: mult.commute)
  qed
next
  have hL: "L (rep_vec L) = (norm (rep_vec L))\<^sup>2"
    by (simp only: rep_vec_works[OF assms] power2_norm_eq_inner)
  have up: "norm (L (rep_vec L)) \<le> onorm L * norm (rep_vec L)"
    by (rule onorm[OF assms])
  show "norm (rep_vec L) \<le> onorm L"
  proof (cases "rep_vec L = 0")
    case True
    then show ?thesis using assms by (simp add: onorm_pos_le[OF assms])
  next
    case False
    have "(norm (rep_vec L))\<^sup>2 = norm (L (rep_vec L))"
      by (simp add: hL)
    also have "\<dots> \<le> onorm L * norm (rep_vec L)"
      by (rule up)
    finally have h2: "(norm (rep_vec L))\<^sup>2 \<le> onorm L * norm (rep_vec L)" .
    have hpos: "0 < norm (rep_vec L)"
      using False by simp
    from h2[unfolded power2_eq_square] hpos show ?thesis
      by (rule mult_right_le_imp_le)
  qed
qed

text \<open>
  合并成 Conway I.3.4 的有限维全文：表示存在且范数相等。
  （唯一性在二维情形可以直接由 Cauchy-Schwarz 的等号条件得到，
  这里作为习题留给读者，Lean 通道 fa_riesz_unique 给出了一般证明。）
\<close>

end
