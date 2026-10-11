theory T01_Prelim
  imports "HOL-Analysis.Elementary_Normed_Spaces"
begin

text \<open>
  第 01 章（Isabelle 通道）：Baire 纲定理与滤子式极限。
  Isabelle 的极限语言也是滤子：(f \<longlongrightarrow> a) F 读作
  "f 沿滤子 F 收敛于 a"，序列极限、函数极限都是特例。
  在自然数上，滤子 sequentially 就是"趋向无穷"的标准滤子。
\<close>

section \<open>Baire 纲定理的 Isabelle 形态\<close>

text \<open>赋范空间中闭集 S 与可数个相对开稠密集，S 含于其交的闭包：\<close>
thm Baire

text \<open>实数的完备性：Cauchy 与 convergent 互相推出
  （正向用 complete_space 实例，反向对任何度量空间成立）：\<close>

lemma real_complete_cauchy_to_conv:
  "Cauchy (X :: nat \<Rightarrow> real) \<Longrightarrow> convergent X"
  by (rule Cauchy_convergent)

lemma real_complete_conv_to_cauchy:
  "convergent (X :: nat \<Rightarrow> real) \<Longrightarrow> Cauchy X"
  by (rule convergent_Cauchy)

section \<open>数列极限：滤子语言的热身\<close>

text \<open>n/(n+1) 趋于 1。路线：恒等变形为 1 - 1/(n+1)，
  而 1/(n+1) 是 1/n 的"平移"，由 LIMSEQ_offset 保持极限。\<close>

lemma tendsto_heatup:
  "((\<lambda>n::nat. real n / (real n + 1)) \<longlongrightarrow> 1) sequentially"
proof -
  have base: "((\<lambda>m::nat. 1 / (of_nat m :: real)) \<longlongrightarrow> 0) sequentially"
    by (rule lim_inverse_n')
  have shifted: "((\<lambda>n::nat. 1 / (real (n + 1))) \<longlongrightarrow> 0) sequentially"
    using LIMSEQ_ignore_initial_segment[OF base, of 1] by simp
  have h1: "((\<lambda>n. 1 - 1 / (real (n + 1)) :: real) \<longlongrightarrow> 1 - 0) sequentially"
    by (intro tendsto_intros shifted)
  have h1': "((\<lambda>n. 1 - 1 / (real (n + 1)) :: real) \<longlongrightarrow> 1) sequentially"
    using h1 by simp
  have ev: "eventually (\<lambda>n::nat. 1 - 1 / (real (n + 1))
      = real n / (real n + 1)) sequentially"
    by (rule always_eventually, simp add: field_split_simps)
  from h1' ev show ?thesis
    by (rule Lim_transform_eventually)
qed

end
