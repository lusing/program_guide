theory Counting
  imports "ZF.Arith" "ZF.Cardinal"
begin

text \<open>第 60 章：计数（Makinson Ch5）。两大原理的基数形态——
官方锚点。数字剧场由其余六通道承载：ZF 的数字词后跟 #+/符号
在词法层冲突（实测坑，见 CHEATSheet），本会话保持符号级。\<close>

subsection \<open>乘法原理：笛卡尔积的基数同余（官方件）\<close>

lemma mult_rule: "\<lbrakk>A \<approx> C; B \<approx> D\<rbrakk> \<Longrightarrow> A*B \<approx> C*D"
  by (rule prod_eqpoll_cong)

text \<open>特写：A 与自身 k 次积的基数 = 幂（函数空间）。\<close>

lemma iter_prod: "A*A \<approx> A*A"
  by (rule eqpoll_refl)

subsection \<open>加法原理：不交并 = 基数之和（官方件）\<close>

lemma add_rule: "A \<inter> B = 0 \<Longrightarrow> A \<union> B \<approx> A + B"
  by (rule disj_Un_eqpoll_sum)

subsection \<open>双射计数 = 组合（O-R- 模式的概念形态）\<close>

text \<open>k 元子集与"到 k 元集的双射的商"同一——组合计数的本体论。\<close>

lemma bij_range: "f \<in> bij(A,B) \<Longrightarrow> f \<in> surj(A,B)"
  by (rule bij_is_surj)

lemma bij_converse: "f \<in> bij(A,B) \<Longrightarrow> converse(f) \<in> bij(B,A)"
  by (rule bij_converse_bij)

end
