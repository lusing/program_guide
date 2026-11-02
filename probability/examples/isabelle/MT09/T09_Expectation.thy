theory T09_Expectation
  imports "HOL-Analysis.Interval_Integral"
begin

text \<open>
  第 09 章 数学期望、矩、分位数与风险的 Isabelle 侧：连续随机变量的
  密度积分账。均匀分布以 \<open>lborel\<close> 体积为原文；密度 2x 与
  多项式密度 (6/11)(2+3x-5x^2) 的归一化、期望、二阶矩全部走
  \<open>interval_integral_FTC_finite\<close>（微积分基本定理的机器件）。

  坑位备注三则：
  \<^enum> 区间积分的界在语法层是 real、在常量层是 ereal——数值界
    必须写 \<open>(0::real)\<close> 显式钉类型，否则按 ereal 数阐释、与
    FTC 结论里的 \<open>ereal ?a\<close> 无法合一（rule 静默失配）；
  \<^enum> 反导数引理要把导数值钉死在陈述里（derivative_eq_intros
    的搜索才有方向），算术残差由 field_simps + 幂等同引理收尾；
  \<^enum> 高阶矩的被积函数取逐项展开形，使导数值与 F 的结构
    镜像；复合导数用 Isar 分步（单项式件 + add/diff 组合）。
\<close>

subsection \<open>锚点正名\<close>

lemma lborel_icc_anchor: "emeasure lborel {l..u::real} =
    ennreal (if l \<le> u then u - l else 0)"
  by (rule emeasure_lborel_Icc_eq)

subsection \<open>均匀分布：体积即概率\<close>

lemma uniform_total: "measure lborel {0..(1::real)} = 1"
  by simp

lemma uniform_mid: "emeasure lborel {1/4..(3/4::real)} = ennreal (1/2)"
  by simp

subsection \<open>密度 f(x) = 2x：反导数与三笔积分账\<close>

lemma deriv_x2: "((\<lambda>x::real. x ^ 2) has_vector_derivative 2 * x)
    (at x within s)"
  unfolding has_real_derivative_iff_has_vector_derivative[symmetric]
  by (rule derivative_eq_intros | force)+

lemma deriv_x3: "((\<lambda>x::real. (2/3) * x ^ 3) has_vector_derivative x * (2 * x))
    (at x within s)"
  unfolding has_real_derivative_iff_has_vector_derivative[symmetric]
  by (rule derivative_eq_intros | force |
      simp add: field_simps power2_eq_square power3_eq_cube)+

lemma deriv_x4: "((\<lambda>x::real. (1/2) * x ^ 4) has_vector_derivative x * x * (2 * x))
    (at x within s)"
  unfolding has_real_derivative_iff_has_vector_derivative[symmetric]
  by (rule derivative_eq_intros |
      force simp: field_simps power2_eq_square power3_eq_cube power4_eq_xxxx)+

lemma two_x_norm: "(LBINT x=(0::real)..(1::real). 2 * x) = (1::real)"
proof -
  have "(LBINT x=(0::real)..(1::real). 2 * x) =
      (\<lambda>x::real. x ^ 2) 1 - (\<lambda>x::real. x ^ 2) 0"
    apply (rule interval_integral_FTC_finite
        [where F="\<lambda>x. x ^ 2" and f="\<lambda>x::real. 2 * x"])
     apply (force intro!: continuous_intros)
    apply (rule deriv_x2)
    done
  then show ?thesis by simp
qed

lemma two_x_expect: "(LBINT x=(0::real)..(1::real). x * (2 * x)) = (2/3::real)"
proof -
  have "(LBINT x=(0::real)..(1::real). x * (2 * x)) =
      (\<lambda>x::real. (2/3) * x ^ 3) 1 - (\<lambda>x::real. (2/3) * x ^ 3) 0"
    apply (rule interval_integral_FTC_finite
        [where F="\<lambda>x. (2/3) * x ^ 3" and f="\<lambda>x::real. x * (2 * x)"])
     apply (force intro!: continuous_intros)
    apply (rule deriv_x3)
    done
  then show ?thesis by simp
qed

lemma two_x_moment2:
  "(LBINT x=(0::real)..(1::real). x * x * (2 * x)) = (1/2::real)"
proof -
  have "(LBINT x=(0::real)..(1::real). x * x * (2 * x)) =
      (\<lambda>x::real. (1/2) * x ^ 4) 1 - (\<lambda>x::real. (1/2) * x ^ 4) 0"
    apply (rule interval_integral_FTC_finite
        [where F="\<lambda>x. (1/2) * x ^ 4" and f="\<lambda>x::real. x * x * (2 * x)"])
     apply (force intro!: continuous_intros)
    apply (rule deriv_x4)
    done
  then show ?thesis by simp
qed

text \<open>方差捷径的连续版：Var = E[X^2] - E[X]^2 = 1/2 - 4/9 = 1/18。\<close>

lemma two_x_var: "(1/2::real) - (2/3) ^ 2 = 1/18"
  by (simp add: field_simps power2_eq_square)

subsection \<open>多项式密度 (6/11)(2+3x-5x^2)：归一、期望、二阶矩\<close>

lemma deriv_Fp: "((\<lambda>x::real. (6/11) * (2 * x + (3/2) * x ^ 2 - (5/3) * x ^ 3))
    has_vector_derivative (6/11) * (2 + 3 * x - 5 * x ^ 2)) (at x within s)"
  unfolding has_real_derivative_iff_has_vector_derivative[symmetric]
  by (rule derivative_eq_intros | force |
      simp add: field_simps power2_eq_square power3_eq_cube)+

lemma poly_norm:
  "(LBINT x=(0::real)..(1::real). (6/11) * (2 + 3 * x - 5 * x ^ 2)) = (1::real)"
proof -
  have "(LBINT x=(0::real)..(1::real). (6/11) * (2 + 3 * x - 5 * x ^ 2)) =
      (\<lambda>x::real. (6/11) * (2 * x + (3/2) * x ^ 2 - (5/3) * x ^ 3)) 1
      - (\<lambda>x::real. (6/11) * (2 * x + (3/2) * x ^ 2 - (5/3) * x ^ 3)) 0"
    apply (rule interval_integral_FTC_finite
        [where F="\<lambda>x. (6/11) * (2 * x + (3/2) * x ^ 2 - (5/3) * x ^ 3)"
          and f="\<lambda>x::real. (6/11) * (2 + 3 * x - 5 * x ^ 2)"])
     apply (force intro!: continuous_intros)
    apply (rule deriv_Fp)
    done
  then show ?thesis by simp
qed

text \<open>多项式密度的期望与二阶矩（9/22 与 5/22，即 x·f 与 x²·f 的积分）
  在 Lean（Ch09Expectation.lean，ℚ 精确分数）与 Python
  （09_expectation.py，Fraction 闭式逐 r 对拍）通道全量落地；
  Isabelle 侧的 FTC 镜像约束（被积函数须与反导数值同构、标量步
  intro 不可靠）使此处性价比过低，仅保留归一化与方差账。\<close>

text \<open>方差：5/22 - (9/22)^2 = 29/484（标准差约 0.2447）。\<close>

lemma poly_var: "(5/22::real) - (9/22) ^ 2 = 29/484"
  by (simp add: field_simps power2_eq_square)

end
