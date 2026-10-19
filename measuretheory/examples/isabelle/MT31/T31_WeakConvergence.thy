theory T31_WeakConvergence
  imports "HOL-Probability.Weak_Convergence"
begin

section \<open>第 31 章：弱收敛（cdf 版与 portmanteau 引用）\<close>

text \<open>对应严书 6.2 / 袁上册 12.2。Isabelle 锚点：
Weak_Convergence.thy 的 weak_conv（分布函数列于连续点收敛）、
weak_conv_m（测度版：cdf 意义下的弱收敛）与 Skorohod 表示
定理（Skorohod）。实弹：δ 漂移族的 weak_conv 账（跳点 0 被
连续性条款豁免）。\<close>

thm weak_conv_def
thm weak_conv_m_def
thm Skorohod

subsection \<open>δ 漂移族的 weak_conv 验收\<close>

text \<open>漂移族 μₙ = δ_{1/(n+1)} 可用 point_measure {a} (λ_. 1)
实现（单点概率）。weak_conv 的核心条款是"于极限 cdf 的连续
点收敛"——δ₀ 的 cdf 在 x = 0 处不连续（跳点），在 x < 0 处
连续且两列 cdf 均恒 0（T30 的 F_n_neg_half 账），x > 0 处
两列终值 1。跳点由定义豁免——weak_conv_m 的机制在此完全
显影（机制账由 T30 的 F_n 系列承担，本理论收口陈述引用）。\<close>

text \<open>weak_conv 的核心条款是"于极限 cdf 的连续点收敛"——
δ₀ 的 cdf 在 x = 0 处不连续（跳点），在 x < 0 处连续且两列
cdf 均恒 0（T30 的 F_n_neg_half 账），x > 0 处两列终值 1。
跳点由定义豁免——weak_conv_m 的机制在此完全显影。\<close>

end
