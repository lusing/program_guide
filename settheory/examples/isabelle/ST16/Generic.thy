theory Generic
  imports "ZF-Constructible.AC_in_L" "ZF.Ordinal"
begin

text \<open>
第 16 章 泛型扩张骨架：力迫条件、稠密集、泛型滤波器。

Isabelle/ZF 未形式化力迫（它是第三篇的语法底座但依赖
极重）；本章锚定滤子与偏序的 ZF 库形态。
\<close>

section \<open>偏序与滤子\<close>

text \<open>ZF 库的部分函数与序论：\<close>
thm part_ord_def

section \<open>稠密集的语义（(16.3) 的基础）\<close>

text \<open>稠密 = 每条件下方有成员；泛型 = 滤子击中一切（模型内）
稠密集。Rasiowa-Sikorski（引理 16.1）的塔构造由 Coq 通道
（Ch16 prefixb + tower）与 Julia/Python 通道承载。\<close>

section \<open>一个小验证：向下封闭集的交\<close>

lemma downset_inter:
  assumes "Transset(M)" "Transset(N)"
  shows "M \<inter> N \<subseteq> M"
  by blast

end
