theory Transitive
  imports "ZF-Constructible.Reflection" "ZF.Ordinal"
begin

text \<open>
第 11 章 传递模型：Mostowski 坍缩与反射原理。

Isabelle/ZF 的 Constructible/Reflection.thy 是反射原理（定理 29）
的**官方形式化**：Mset 层级逐联结词地建立 reflection 引理，
最后合成"V_α 反射任意公式"的主定理。Mostowski 坍缩的完整
形式化在库中缺席（定理 28 由计算通道与讲义承载）。
\<close>

section \<open>反射原理的官方形态（定理 29）\<close>

text \<open>Mset 层级（构造层级的前奏）：\<close>
thm Mset_mono

text \<open>逐联结词的反射引理（归纳的每一步）：\<close>
thm Not_reflection

thm And_reflection

text \<open>主定理的合成形态：\<close>
thm Reflection

section \<open>传递闭包（坍缩的伴侣工具）\<close>

text \<open>传递闭包 TC(x)：包含 x 的最小传递集——坍缩的构造材料。\<close>
thm TC_def

end
