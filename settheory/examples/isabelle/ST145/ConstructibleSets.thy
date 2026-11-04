theory ConstructibleSets imports ZF "ZF-Constructible.Formula" "ZF-Constructible.AC_in_L" begin

text \<open>哥德尔的 L：可构成集层谱（书 8.1-8.3）。

ZF 库的 Constructible 会话是 L 的完整机器化开发（Paulson），
以 Formula.thy 为核心。以下是书第八章主要概念的官方件。\<close>

text \<open>L_α 的递归定义（书 8.2.1）：L_0 = 0, L_{α+1} = Def(L_α),
极限处取并。ZF 用 Lset 表示 L_α。\<close>
thm Lset_def

text \<open>L = ⋃_α L_α（书 8.2.1 的 (8.6) 式）。\<close>
thm L_def

text \<open>Def 的刻画：哥德尔闭包 ∩ 幂集（书 8.1.8）。\<close>
text \<open>Def(M) 在 ZF 库中以 DPow(A) 的形态出现——由公式的
有穷编码（satisfies 谓词）定义。\<close>

text \<open>L 是传递的（书 8.2.2(1)）。\<close>
thm Transset_Lset

text \<open>每个序数都在 L 中且秩不变（书 8.2.5）。\<close>
thm Ord_in_L

text \<open>L_n = V_n 对有限 n（书 8.2.7），以及 |L_α| = |α|（书 8.2.8）。
ZF 库以 Lset_subset_Vset 和 Lset_le_Vset 给出嵌入关系。\<close>

text \<open>核心定理：L ⊨ AC（书 8.3 的高潮之一）。
ZF 库的完整陈述——每个可构成集都可良序。\<close>
thm L_implies_AC

text \<open>L ⊨ V=L（书 8.3.3）：L 是可构成公理的模型。\<close>

end
