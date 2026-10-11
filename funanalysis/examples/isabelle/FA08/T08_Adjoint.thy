theory T08_Adjoint
  imports "HOL-Analysis.Cartesian_Euclidean_Space"
begin

text \<open>
  第 08 章（Isabelle 通道）：伴随算子（Conway II.2）在 real^2 的化身。
  对线性 A 构造转置伴随 adj2 A（按标准基转置），
  证定义性质 inner (A x) y = inner x (adj2 A y)（Conway 2.3）
  与唯一性（Conway 2.2 的唯一性部分）。
\<close>

section \<open>伴随的构造：按标准基转置\<close>

definition adj2 :: "(real^2 \<Rightarrow> real^2) \<Rightarrow> real^2 \<Rightarrow> real^2" where
  "adj2 A y = (\<chi> k. \<Sum>j\<in>UNIV. (A (axis j 1)) $ k * y $ j)"

section \<open>定义性质（Conway 2.3）\<close>

theorem adj2_inner:
  assumes lin: "linear A"
  shows "inner (A x) y = inner x (adj2 A y)"
proof -
  interpret Alin: linear A by (rule lin)
  have reprF: "(\<Sum>i\<in>UNIV. x $ i *\<^sub>R axis i 1) = x"
    using basis_expansion [of x] by (simp add: scalar_mult_eq_scaleR)
  have Ax: "A x = (\<Sum>i\<in>UNIV. x $ i *\<^sub>R A (axis i 1))"
  proof -
    have h1: "A x = A ((\<Sum>i\<in>UNIV. x $ i *\<^sub>R axis i 1))"
      by (subst reprF) (rule refl)
    have step1: "A ((\<Sum>i\<in>UNIV. x $ i *\<^sub>R axis i 1))
        = (\<Sum>i\<in>UNIV. A (x $ i *\<^sub>R axis i 1))"
      by (rule Alin.sum)
    have step2: "\<And>i. A (x $ i *\<^sub>R axis i 1) = x $ i *\<^sub>R A (axis i 1)"
      by (rule Alin.scale)
    have h2: "A ((\<Sum>i\<in>UNIV. x $ i *\<^sub>R axis i 1))
        = (\<Sum>i\<in>UNIV. x $ i *\<^sub>R A (axis i 1))"
      using step1 step2 by simp
    show ?thesis using h1 h2 by simp
  qed
  have "inner (A x) y = (\<Sum>i\<in>UNIV. x $ i * inner (A (axis i 1)) y)"
    unfolding Ax by (simp add: inner_sum_left inner_scaleR_left)
  also have "\<dots> = (\<Sum>i\<in>UNIV. x $ i * (\<Sum>k\<in>UNIV. (A (axis i 1)) $ k * y $ k))"
    by (simp add: inner_vec_def)
  also have "\<dots> = (\<Sum>k\<in>UNIV. (\<Sum>j\<in>UNIV. (A (axis j 1)) $ k * y $ j) * x $ k)"
    by (simp add: sum.swap sum_distrib_left algebra_simps)
  also have "\<dots> = inner x (adj2 A y)"
    unfolding adj2_def inner_vec_def by simp
  finally show ?thesis .
qed

section \<open>唯一性（Conway 2.2 唯一性部分）\<close>

theorem adj2_unique:
  assumes h1: "\<And>x y. inner (A x) y = inner x (B1 y)"
      and h2: "\<And>x y. inner (A x) y = inner x (B2 y)"
  shows "B1 = B2"
proof -
  have "\<And>y. B1 y - B2 y = 0"
  proof -
    fix y
    have hall: "\<And>x. inner x (B1 y - B2 y) = 0"
      by (metis h1 h2 inner_diff_right right_minus_eq)
    have hself: "inner (B1 y - B2 y) (B1 y - B2 y) = 0"
      by (rule hall)
    then show "B1 y - B2 y = 0"
      by (simp add: inner_eq_zero_iff)
  qed
  then show ?thesis by auto
qed

end
