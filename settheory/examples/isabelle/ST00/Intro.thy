theory Intro
  imports "ZF-Constructible.Formula" "ZF.CardinalArith"
begin

text \<open>
第 00 章 导引：ZF object-logic 的世界。

Isabelle/ZF 与 Lean 的 Type 宇宙不同：它直接把无类型一阶集合论
做进逻辑内核。全类 V 在这里无法命名（只有集合变量），但每一集合
变元都是全类 V 的"居民"。我们抽查几个马上要用到的库锚点。
\<close>

text \<open>外延公理：集合由元素决定。它是 ZF 库的公理之一：\<close>
thm extension

text \<open>替换公理模式的一个实例化形态（ZF 库公理）：\<close>
thm replacement

text \<open>无穷公理的表述：\<close>
thm infinity

text \<open>序数是传递且被 \<in> 良序化的集合。序数三歧性：\<close>
thm Ord_linear_lt

text \<open>基数为序数的世界：Card(K) 即初始序数。\<close>
thm Card_is_Ord

text \<open>第一个练习：空集是任何集合的子集。\<close>
lemma empty_subset: "0 \<subseteq> A"
  by auto

text \<open>传递集合的教科书刻画（Ordinal.thy 已备）：\<close>
thm Transset_iff_Union_subset

end
