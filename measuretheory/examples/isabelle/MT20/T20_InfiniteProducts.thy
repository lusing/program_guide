theory T20_InfiniteProducts
  imports "HOL-Probability.Infinite_Product_Measure"
begin

section \<open>第 20 章：无穷乘积测度（均匀硬币的柱集账）\<close>

text \<open>对应严书 4.4。Isabelle 锚点：Infinite_Product_Measure.thy
的 product_prob_space locale（PiM 无穷乘积）+ emeasure_PiM
（有限框账）+ distr_PiM_restrict_finite（有限维边际复原）。
均匀硬币在 bool 上取 uniform_count_measure，n 次全正面的
柱集账 = (1/2)^n。注意：全局 interpretation 会触发本版
product_prob_space 子 locale 的注册事故（"Illegal fixed
variable I"），源代码自身的用法是**证明内局部 interpret**——
本理论照此办理。\<close>

definition coin :: "bool measure" where
  "coin = uniform_count_measure (UNIV::bool set)"

lemma prob_space_coin: "prob_space coin"
  by (simp add: coin_def prob_space_uniform_count_measure)

lemma coin_True: "emeasure coin {True} = inverse (2::ennreal)"
  by (simp add: coin_def emeasure_uniform_count_measure)

subsection \<open>有限框账：n 次全正面 = (1/2)^n\<close>

lemma n_flips_all_true:
  "emeasure (PiM {0..<n::nat} (\<lambda>_. coin)) (PiE {0..<n} (\<lambda>_. {True})) = (inverse (2::ennreal))^n"
proof -
  interpret C: product_prob_space "(\<lambda>_::nat. coin)"
    by (intro product_prob_spaceI) (simp add: prob_space_coin)
  have "emeasure (PiM {0..<n::nat} (\<lambda>_. coin)) (PiE {0..<n} (\<lambda>_. {True}))
      = (\<Prod>i\<in>{0..<n}. emeasure coin {True})"
    by (rule C.emeasure_PiM) (auto simp: coin_def sets_uniform_count_measure)
  also have "\<dots> = (inverse (2::ennreal))^n"
    by (simp add: coin_True)
  finally show ?thesis .
qed

subsection \<open>无穷乘积 locale：边际复原引用\<close>

lemma coin_distr_PiM_restrict_finite:
  assumes "finite J" "J \<subseteq> (UNIV::nat set)"
  shows "distr (PiM (UNIV::nat set) (\<lambda>_. coin)) (PiM J (\<lambda>_. coin))
          (\<lambda>x. restrict x J) = PiM J (\<lambda>_. coin)"
proof -
  interpret C: product_prob_space "(\<lambda>_::nat. coin)" "UNIV::nat set"
    by (intro product_prob_spaceI) (simp add: prob_space_coin)
  show ?thesis using assms
    by (rule C.distr_PiM_restrict_finite)
qed

end
