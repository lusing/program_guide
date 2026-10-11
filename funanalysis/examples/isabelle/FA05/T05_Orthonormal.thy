theory T05_Orthonormal
  imports "HOL-Analysis.Cartesian_Euclidean_Space"
begin

text \<open>
  第 05 章（Isabelle 通道）：标准正交系（Conway I.4）在 real^2 的化身。
  走 FA00 已验证的 axis-δ 计算风格：
  标准基的正交性、Parseval（具体向量 (3,4)）、Bessel（部分系能量）、
  Gram-Schmidt 的起点（两个不正交的具体向量）。
\<close>

section \<open>标准基的标准正交性（Conway 4.4）\<close>

lemma std_basis_orthogonal:
  "i \<noteq> j \<Longrightarrow> inner (axis i 1 :: real^2) (axis j 1) = 0"
  by (simp add: inner_axis_axis)

lemma std_basis_unit:
  "inner (axis i 1 :: real^2) (axis i 1) = 1"
  by (simp add: inner_axis_axis)

section \<open>Parseval：具体向量 (3,4)（Conway 4.13 有限版）\<close>

lemma parseval_concrete:
  fixes x :: "real^2"
  defines "x \<equiv> 3 *\<^sub>R axis 0 1 + 4 *\<^sub>R axis 1 1"
  shows "norm x ^ 2
     = (inner x (axis 0 1)) ^ 2 + (inner x (axis 1 1)) ^ 2"
proof -
  have ixy0: "inner x (axis 0 1) = 3"
    unfolding x_def by (simp add: inner_add_left inner_add_right
        inner_scaleR_left inner_scaleR_right inner_axis_axis)
  have ixy1: "inner x (axis 1 1) = 4"
    unfolding x_def by (simp add: inner_add_left inner_add_right
        inner_scaleR_left inner_scaleR_right inner_axis_axis)
  have inx: "norm x ^ 2 = 25"
    unfolding x_def by (simp add: power2_norm_eq_inner inner_add_left
        inner_add_right inner_scaleR_left inner_scaleR_right inner_axis_axis)
  show ?thesis unfolding ixy0 ixy1 inx by simp
qed

section \<open>Bessel：部分系能量不超过全能量（Conway 4.8）\<close>

lemma bessel_one_of_two:
  fixes x :: "real^2"
  defines "x \<equiv> 3 *\<^sub>R axis 0 1 + 4 *\<^sub>R axis 1 1"
  shows "(inner x (axis 0 1)) ^ 2 \<le> norm x ^ 2"
proof -
  have ixy0: "inner x (axis 0 1) = 3"
    unfolding x_def by (simp add: inner_add_left inner_add_right
        inner_scaleR_left inner_scaleR_right inner_axis_axis)
  have inx: "norm x ^ 2 = 25"
    unfolding x_def by (simp add: power2_norm_eq_inner inner_add_left
        inner_add_right inner_scaleR_left inner_scaleR_right inner_axis_axis)
  show ?thesis unfolding ixy0 inx by simp
qed

section \<open>Gram-Schmidt 的起点（Conway 4.6）：两个不正交的向量\<close>

text \<open>v1 = e0 + e1 与 v2 = e0 的内积为 1 而非 0；
  Gram-Schmidt 把 v2 换成 v2 - (inner v2 v1 / inner v1 v1) \<cdot> v1 后才正交。\<close>

lemma gs_start_not_orthogonal:
  "inner (axis 0 1 + axis 1 1 :: real^2) (axis 0 1) = 1"
  by (simp add: inner_add_left inner_axis_axis)

end
