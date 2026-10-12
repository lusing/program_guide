theory T54_FredholmDet
  imports "HOL-Analysis.Cartesian_Euclidean_Space"
  "HOL-Analysis.Determinants"
begin

text \<open>
  第 54 章（Isabelle 通道）：Fredholm 行列式理论的 2x2 种子。
  det(I + tM) 的特征多项式恒等式同时编码了：
    - 谱-零点对应（D 的零点 = 特征值的倒数的负值）；
    - 迹公式的种子（D 的 t 系数 = tr M，即 dD/dt 在 0 处 = tr）。
\<close>

definition I_plus_t :: "real \<Rightarrow> real \<Rightarrow> real \<Rightarrow> real \<Rightarrow> real \<Rightarrow> real^2^2" where
  "I_plus_t a b c d t = (\<chi> i j. if i = 1 \<and> j = 1 then 1 + t*a
                                else if i = 1 \<and> j = 2 then t*b
                                else if i = 2 \<and> j = 1 then t*c
                                else 1 + t*d)"

lemma det_I_plus_t:
  fixes a b c d t :: real
  shows "det (I_plus_t a b c d t) = 1 + t*(a + d) + t^2*(a*d - b*c)"
proof -
  have e00: "(I_plus_t a b c d t) $ 1 $ 1 = 1 + t*a" unfolding I_plus_t_def by simp
  have e01: "(I_plus_t a b c d t) $ 1 $ 2 = t*b" unfolding I_plus_t_def by simp
  have e10: "(I_plus_t a b c d t) $ 2 $ 1 = t*c" unfolding I_plus_t_def by simp
  have e11: "(I_plus_t a b c d t) $ 2 $ 2 = 1 + t*d" unfolding I_plus_t_def by simp
  show ?thesis
    unfolding det_2 e00 e01 e10 e11
    by (simp add: algebra_simps power2_eq_square)
qed

text \<open>迹公式种子：D(t) 在 0 处的导数 = 对角和（迹）。\<close>

lemma trace_formula_seed:
  fixes a b c d :: real
  shows "((\<lambda>t. det (I_plus_t a b c d t)) has_real_derivative (a + d)) (at 0)"
proof -
  have hEq: "\<And>t. det (I_plus_t a b c d t) = 1 + t*(a + d) + t^2*(a*d - b*c)"
    using det_I_plus_t by blast
  have hEq2: "\<And>t. det (I_plus_t a b c d t) = 1 + (a + d)*t + (a*d - b*c)*t^2"
    using det_I_plus_t by (simp add: algebra_simps)
  have h3: "((\<lambda>t. 1 + (a + d)*t + (a*d - b*c)*t^2) has_real_derivative
             (0 + (a + d) + (a*d - b*c)*(2*0))) (at 0)"
    by (rule derivative_eq_intros | simp)+
  have h4: "((\<lambda>t. 1 + (a + d)*t + (a*d - b*c)*t^2) has_real_derivative
             (a + d)) (at 0)"
    using h3 by simp
  show ?thesis
    apply (subst hEq2)
    by (rule h4)
qed

text \<open>谱-零点对应的 2x2 版（对角情形）：t = -1/a 是 D 的零点。\<close>

lemma zero_of_diagonal:
  fixes a d :: real
  assumes "a \<noteq> 0"
  shows "det (I_plus_t a 0 0 d (- 1 / a)) = 0"
proof -
  have h: "det (I_plus_t a 0 0 d (- 1 / a)) =
           1 + (- 1 / a)*(a + d) + (- 1 / a)^2*(a*d)"
    using det_I_plus_t[of a 0 0 d "- 1 / a"] by simp
  also have "... = 0" using assms
    by (simp add: field_simps power2_eq_square)
  finally show ?thesis .
qed

end
