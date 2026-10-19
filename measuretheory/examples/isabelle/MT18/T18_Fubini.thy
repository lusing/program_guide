theory T18_Fubini
  imports "HOL-Analysis.Analysis"
begin

section \<open>第 18 章：乘积测度与 Fubini 定理（矩形账与换序）\<close>

text \<open>对应严书 4.2 / 袁上册 10.2-10.3。Isabelle 锚点：
Binary_Product_Measure.thy 的 pair_sigma_finite locale——
Fubini/Fubini'（换序定理，nn_integral 版）与
emeasure_pair_measure_Times（矩形账）。这里在有限计数空间上
做矩形账实弹，并给出换序定理的陈述引用与有限影子。\<close>

subsection \<open>矩形账：计数 × 计数\<close>

lemma pair_count_rect:
  "emeasure (count_space {0, 1::nat} \<Otimes>\<^sub>M count_space {2, 3::nat}) ({0} \<times> {2}) = 1"
proof -
  have sf: "sigma_finite_measure (count_space {2, 3::nat})"
    by (rule sigma_finite_measure_count_space_countable) simp
  have "emeasure (count_space {0, 1::nat} \<Otimes>\<^sub>M count_space {2, 3::nat}) ({0} \<times> {2})
      = emeasure (count_space {0, 1::nat}) {0} * emeasure (count_space {2, 3::nat}) {2}"
    by (rule sigma_finite_measure.emeasure_pair_measure_Times[OF sf]) auto
  then show ?thesis by simp
qed

subsection \<open>换序定理：陈述引用与有限影子\<close>

text \<open>Fubini（pair_sigma_finite locale，非负可测函数）：两个累次
nn-积分相等——Tonelli 执照的 Isabelle 原文。\<close>

thm pair_sigma_finite.Fubini
thm pair_sigma_finite.Fubini'

text \<open>有限影子：2×2 矩阵的双重和换序（Finset.sum_comm）。
"有执照"的正面案例：绝对可和时两序一致；无执照的 a-(m,n)
反例（1 vs 0）由 Julia/Python 数值通道对拍。\<close>

lemma sum_swap22:
  fixes c :: "nat \<Rightarrow> nat \<Rightarrow> ennreal"
  shows "(\<Sum>m\<in>{0, 1}. (\<Sum>n\<in>{0, 1}. c m n)) = (\<Sum>n\<in>{0, 1}. (\<Sum>m\<in>{0, 1}. c m n))"
  by (rule sum.swap)

end
