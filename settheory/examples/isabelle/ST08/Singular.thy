theory Singular
  imports "ZF.CardinalArith"
begin

text \<open>
第 08 章 奇异基数：后继基数构造与 SCH 的语义。

ZF 库的 CardinalArith 提供 csucc（最小更大基数）；SCH
（奇异基数假设：cf \<kappa> < \<kappa> 时 \<kappa>^cf\<kappa> = \<kappa>⁺）
与 Silver 定理的完整机器化由讲义与计算通道承载——ZF 库
没有共尾性理论。
\<close>

section \<open>csucc：后继基数的官方构造\<close>

text \<open>K < csucc(K) 且 csucc(K) 是基数：\<close>
thm csucc_basic

text \<open>csucc 的最小性：任何更大的基数 L 满足 csucc(K) \<le> L：\<close>
thm csucc_le

section \<open>SCH 的语义框架\<close>

text \<open>在 ZFC + GCH 下，幂运算完全确定（引理 8.1）：
    \<kappa>^\<lambda> = \<kappa>       若 2^\<lambda> \<le> \<kappa> 且 \<lambda> < cf \<kappa>
    \<kappa>^\<lambda> = \<kappa>⁺      若 2^\<lambda> < \<kappa> 且 \<lambda> \<ge> cf \<kappa>
    （第三种情形 2^\<lambda> > \<kappa> 时 \<kappa>^\<lambda> = 2^\<lambda>）。
    Silver 定理（定理 23）：GCH 在不可数共尾的奇异基数之下
    成立则在该基数成立——"传染性"。\<close>

text \<open>Jensen 覆盖引理的推论（讲义）：SCH 失败 \<Longrightarrow> 0# 存在
    ——大基数的第一个深刻等价（第 33 章正题）。\<close>

section \<open>一个小验证：可数并的基数\<close>

text \<open>引理 5.1 在 aleph 语境：\<aleph>_\<omega> 是 \<aleph>_n 的可数并
    （这就是 cf \<aleph>_\<omega> = \<omega> 的语义——ZF 侧以 csucc
    链条呈现）。\<close>

lemma csucc_iterates_grow:
  assumes "Ord(K)" shows "K < csucc(K)"
  by (rule csucc_basic [OF assms, THEN conjunct2])

end
