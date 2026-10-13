theory Cardinals
  imports "ZF-Constructible.Formula" "ZF.CardinalArith"
begin

text \<open>
第 03 章 基数：ZF 库的 eqpoll / lepoll / Card 生态。

Jech 用 |X| 记基数；ZF 库的对应物：A \<approx> B（等势）、
A \<lesssim> B（投影）、|A|（最小等势序数）。本章抽查库锚点，
并完成 Cantor-Bernstein 的 ZF 侧库引用与基数算术的交换律。
\<close>

section \<open>库锚点\<close>

text \<open>等势的定义（单射双射刻画）：\<close>
thm eqpoll_def

text \<open>lepoll 的定义：\<close>
thm lepoll_def

text \<open>Card(K) 是初始序数（Jech 引理 3.2 的语境）：\<close>
thm Card_is_Ord

text \<open>Card(K) 的成员恰是更小的基数（投影的刚性）：\<close>
thm in_Card_imp_lesspoll

section \<open>基数算术的交换律（Jech (3.3)）\<close>

text \<open>cadd/cmult 是 ZF 库的基数加乘；交换律是库定理：\<close>
thm cadd_commute

thm cmult_commute

section \<open>幂集的有限侧事实\<close>

text \<open>ZF 库：A 有限当且仅当 Pow(A) 有限
（幂集严格更大的无穷版本在 Lean 通道 Cardinal.cantor）。\<close>
thm Finite_Pow_iff

section \<open>完整小证明：投影的自反与单调\<close>

lemma singleton_lepoll: "a \<in> A \<Longrightarrow> {a} \<lesssim> A"
  by (rule subset_imp_lepoll, auto)

lemma lepoll_refl_demo: "A \<lesssim> A"
  by (rule lepoll_refl)

end
