theory T52_CLT
  imports "HOL-Probability.Central_Limit_Theorem"
begin

section \<open>第 52 章：中心极限定理（Isabelle 锚点）\<close>

text \<open>对应袁下册第 21 章。Isabelle 锚点
（Probability/Central_Limit_Theorem.thy）：
`central_limit_theorem`（prob_space locale 下的 iid CLT 完全体：
indep_vars + 同均值 m + 方差 σ² + 同分布 \<mu> 四前提
⟹ 部分和标准化的分布弱收敛到 `std_normal_distribution`）；
其零均值版 `central_limit_theorem_zero_mean` 是主证明的进料口。
目标形态 `weak_conv_m`（弱收敛的分布列版）与极限户口
`std_normal_distribution`（density lborel std_normal_density，
定义于 Characteristic_Functions.thy）与 Lean 侧
`TendstoInDistribution` + `gaussianReal` 的互译由 docs 52.8
对照表承载。\<close>

subsection \<open>锚点正名\<close>

thm prob_space.central_limit_theorem
thm prob_space.central_limit_theorem_zero_mean
thm weak_conv_m_def
thm Characteristic_Functions.real_dist_normal_dist

text \<open>读法对照：Isabelle 的结论形态是
`weak_conv_m (λn. distr M borel (λx. (\<Sum>i<n. X' i x) / sqrt (n*σ²))) std_normal_distribution`
——把"依分布收敛"翻译成"分布测度列弱收敛"，与 Lean 的
`TendstoInDistribution ... atTop Y (fun _ => P) P'`（以任意
承载者 Y 的 HasLaw 表述）是同一陈述的两种户口。
前提侧：`indep_vars (λi. borel) X UNIV`（函数级独立族）对应
Lean `iIndepFun X P`；`X_distrib`（逐个同分布）对应
`IdentDistrib`；方差前提 `X_variance: variance (X n) = σ²`
在 Lean 版由 `MemLp (X 0) 2` + `HasLaw Y (gaussianReal 0 Var.toNNReal)`
以"极限方差 = 项方差"的形态吸收——同一 theorem 的两种记账法。\<close>

end
