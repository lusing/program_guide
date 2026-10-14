theory Probability
  imports "ZF.EquivClass"
begin

text \<open>第 61 章：有限概率（Makinson Ch6）。条件概率的符号级事实：
分子同一（p(A|B) 与 p(B|A) 共享交事件），分母不同故不可交换。
比值与数字剧场由其余六通道承载（ZF 数值词词法坑，见 ST60 注）。\<close>

subsection \<open>条件概率：分子相同\<close>

definition cond_num :: "[i\<Rightarrow>i, i, i] \<Rightarrow> i" where
  "cond_num(p,A,B) \<equiv> p(A\<inter>B)"

lemma cond_same_numerator:
  "cond_num(p,A,B) = cond_num(p,B,A)"
  by (simp add: cond_num_def Int_commute)

subsection \<open>条件化：投影即再归一化的概率函数（61.3 的第 3 坑）\<close>

text \<open>A|B 不是集合而是有序对——条件化是函数层面的操作：
  p_B(A) := p(A|B)。其"迭代坍缩"p_(B∩C) = (p_B)_C 在符号级
  由交的结合/交换承载。\<close>

lemma inter_assoc_comm: "A\<inter>(B\<inter>C) = (A\<inter>B)\<inter>C"
  by (simp add: Int_assoc)

end
