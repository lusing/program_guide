theory CardArith
  imports "ZF.CardinalArith" "ZF.Cardinal_AC"
begin

text \<open>
第 06 章 基数算术：cadd / cmult / 无穷和积的 ZF 库生态。

ZF 的 CardinalArith 定义 cadd(i,j) 与 cmult(i,j)（基数加乘），
Cardinal_AC 提供 AC 下的基数算术（排序引理等）。König 定理
在 ZF 库没有现成形态——其完整机器化由 Lean 的 Cantor/幂理论
与本章讲义承载。
\<close>

section \<open>库锚点\<close>

text \<open>基数加法的交换（Jech (3.3)/(6.3) 的运算层）：\<close>
thm cadd_commute

text \<open>基数加法结合律：\<close>
thm well_ord_cadd_assoc

text \<open>基数乘法对加法的分配（左）：\<close>
thm well_ord_cadd_cmult_distrib

text \<open>无穷基数的吸收律：InfCard(K) \<Longrightarrow> K \<otimes> K = K
     ——Jech 定理 8（\<kappa>.\<kappa>=\<kappa>）的 ZF+AC 机器形态：\<close>
thm InfCard_square_eqpoll

section \<open>应用示例：可数基数的运算\<close>

text \<open>InfCard(nat)：\<nat> 是无穷基数载体。\<close>
thm InfCard_nat

text \<open>于是 nat\<otimes>nat = nat：可数×可数 = 可数（定理 8 特例）。\<close>

lemma countable_square: "nat \<times> nat \<approx> nat"
  by (rule InfCard_square_eqpoll [OF InfCard_nat])

end
