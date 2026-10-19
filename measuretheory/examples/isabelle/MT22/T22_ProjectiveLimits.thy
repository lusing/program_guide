theory T22_ProjectiveLimits
  imports "HOL-Probability.Projective_Limit"
begin

section \<open>第 22 章：投影极限（塔上的边际账）\<close>

text \<open>对应严书 4.6。mathlib 侧 IsProjectiveLimit 谓词族的镜像：
Isabelle 用 projective_family locale 表达"层间咬合"，lim 即
投影极限测度。Cantor 塔语境（Bool 因子、截断粘合）的实弹：
三层塔压回两层，账一致；存在性引用 limP_eq_PiM（乘积族的
极限 = PiM——同一定理的两套坐标）。与第 21 章同一条引理
（distr_restrict）的不同 instantiation。\<close>

definition coin :: "bool measure" where
  "coin = uniform_count_measure (UNIV::bool set)"

lemma prob_space_coin: "prob_space coin"
  by (simp add: coin_def prob_space_uniform_count_measure)

subsection \<open>Cantor 塔的边际账：{0,1,2} 压回 {0,1}\<close>

lemma tower_marginal:
  shows "PiM {0, 1::nat} (\<lambda>_. coin)
      = distr (PiM {0, 1, 2} (\<lambda>_. coin)) (PiM {0, 1} (\<lambda>_. coin))
          (\<lambda>f. restrict f {0, 1::nat})"
proof -
  interpret CP: product_prob_space "(\<lambda>_::nat. coin)" "{0, 1, 2::nat}"
    by (intro product_prob_spaceI) (simp add: prob_space_coin)
  show ?thesis
    by (rule CP.distr_restrict) simp_all
qed

text \<open>柱集账在两层塔间的搬运：prod_emb（柱集嵌入）下的测度
不变——emeasure_prod_emb 是 mathlib 侧 IsProjectiveLimit.
measure_cylinder 的 Isabelle 镜像。\<close>

thm product_prob_space.emeasure_prod_emb

subsection \<open>极限测度与 PiM 的换算\<close>

thm polish_projective.emeasure_lim_emb
thm polish_product_prob_space.limP_eq_PiM

end
