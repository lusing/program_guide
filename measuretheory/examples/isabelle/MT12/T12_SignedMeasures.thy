theory T12_SignedMeasures
  imports "HOL-Analysis.Analysis"
begin

section \<open>第 12 章：Radon-Nikodym 定理（RN_deriv 正名与有限实例）\<close>

text \<open>对应严书 3.3.11。Isabelle 的 RN 导数是常值函数 RN_deriv
（Radon_Nikodym.thy），核心定理 RN_derivI：绝对连续时
density M (RN_deriv M N) = N——与 mathlib 的 withDensity_rnDeriv_eq
互为镜像。这里在有限计数空间上做引用实例。\<close>

subsection \<open>RN_derivI 引用实例：密度测度的还原\<close>

lemma rn_density_count:
  fixes f :: "nat \<Rightarrow> ennreal"
  assumes "f 0 = 2" "f (Suc 0) = 3"
  shows "density (count_space {0,1::nat}) f = density (count_space {0,1}) f"
  by simp

text \<open>真正的还原引理：RN_derivI 只需两条件——f 可测、density M f = N
（密度已存在时，RN_deriv 的 SOME-选择子给出良定还原）。σ-有限的
存在性定理在 Isabelle 侧是 RN_deriv_unique_sigma_finite 一族。\<close>

lemma rn_deriv_restore:
  fixes f :: "nat \<Rightarrow> ennreal"
  assumes meaf: "f \<in> borel_measurable (count_space {0,1::nat})"
  shows "density (count_space {0,1::nat})
           (RN_deriv (count_space {0,1}) (density (count_space {0,1}) f))
       = density (count_space {0,1}) f"
  by (rule RN_derivI[OF meaf refl])

end
