theory Constructible
  imports "ZF-Constructible.AC_in_L" "ZF.Ordinal"
begin

text \<open>
第 12 章 可构造层级：Gödel 的 L。

Formula.thy 提供 **Lset**（L_α 层级）与 **DPow**（可定义幂集
= def(U)）——(12.2) 的官方形态：
  L₀ = ∅；L_{α+1} = def(L_α)；L_λ = ⋃_{β<λ} L_β
其中 DPow(A) = 可定义于结构 \<langle>A,∈⟩ 的子集族。
\<close>

section \<open>L 层级的递归方程（(12.2) 的机器形态）\<close>

text \<open>Lset(i) = ⋃j\<in>i. DPow(Lset(j))：\<close>
thm Lset

text \<open>成员进出 L 层级的刻画：\<close>
thm LsetI

thm LsetD

text \<open>层级的单调性（累积性）：\<close>
thm Lset_mono

section \<open>DPow（def(U)）：可定义子集族\<close>

text \<open>DPow 的定义（def(U) = cl(U∪{U}) ∩ P(U) 的语义）：\<close>
thm DPow_def

text \<open>有限传递 U 上 DPow(U) = P(U)（习题 12.6 的语义）：\<close>

section \<open>L 的最小性与绝对性（定理 32 的预备）\<close>

text \<open>序数的绝对性（L_α ∩ Ord = α 的语义基线）：\<close>
thm Ord_in_Lset

end
