theory T11_LimitTheorems
  imports "HOL-Analysis.Analysis"
begin

section \<open>第 11 章：积分号下取极限（Fatou 的机器正名与有限实例）\<close>

text \<open>对应严书 3.2。Isabelle 的 Fatou 引理是 nn_integral_liminf：
  \<open>(\<integral>\<^sup>+ x. liminf (\<lambda>n. f n x) \<partial>M) \<le> liminf (\<lambda>n. \<integral>\<^sup>+ x. f n x \<partial>M)\<close>。
单边控制收敛有 integral_dominated_convergence（Bochner 层）。
这里做两件事：Fatou 的引用实例（常值列取等）与有限链上
单调收敛的显式账。\<close>

subsection \<open>Fatou：引用实例（终归常值列取等号）\<close>

lemma fatou_const_eq:
  "(\<integral>\<^sup>+x. liminf (\<lambda>n::nat. indicator {1::nat} x)
      \<partial>count_space {0,1::nat})
   \<le> liminf (\<lambda>n. (\<integral>\<^sup>+x. indicator {1::nat} x \<partial>count_space {0,1}))"
proof (rule nn_integral_liminf)
  show "\<And>i. (\<lambda>x. indicator {1::nat} x) \<in> borel_measurable (count_space {0,1::nat})"
    by measurable
qed

subsection \<open>单调收敛：有限链的显式账\<close>

text \<open>链 f_1 = 0，f_2 = I{1}，f_3 = I{0}+I{1}：积分 0、1、2
（count_space{0,1} 的总质量 2）。上行 MCT 在有限链上退化为
有限单调性，顶点积分即极限积分。\<close>

lemma mct_finite_chain:
  "(\<integral>\<^sup>+x. 0 \<partial>count_space {0,1::nat}) = 0"
  "(\<integral>\<^sup>+x. indicator {1::nat} x \<partial>count_space {0,1}) = 1"
  "(\<integral>\<^sup>+x. indicator {0::nat} x + indicator {1::nat} x \<partial>count_space {0,1}) = 2"
  by (simp_all add: nn_integral_count_space_finite)

end
