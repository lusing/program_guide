theory Foundation
  imports "ZF.Univ"
begin

text \<open>
第 09 章 正则公理与秩层级：ZF 库的 Vfrom 理论。

Univ.thy 定义 Vfrom(A, i)（从 A 出发的累积层级），对应
Jech 的 V_α = Vfrom(0, α)。本章抽取层级递归、单调性与
rank 关联的官方锚点。
\<close>

section \<open>层级的递归方程（Jech 的 V_α 定义）\<close>

text \<open>Vfrom(A,i) = A \<union> \<Union>j\<in>i. Pow(Vfrom(A,j))
     ——后继步取幂、极限步取并的统一递归：\<close>
thm Vfrom

text \<open>第 0 层就是种子：\<close>
thm Vfrom_0

section \<open>单调性与成员推进\<close>

text \<open>j < i ⟹ Vfrom(A,j) \<subseteq> Vfrom(A,i)：\<close>
thm Vfrom_mono

text \<open>层级内的成员关系随层推进：\<close>
thm VfromI

section \<open>rank 关联（宇宙的骨架定理）\<close>

text \<open>Vfrom(A, rank(x)) = Vfrom(A, x)——秩决定层级归属：\<close>
thm Vfrom_rank_eq

text \<open>正则公理（foundation）在 ZF 内核是公理：\<close>
thm foundation

end
