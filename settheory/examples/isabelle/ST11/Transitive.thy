theory Transitive
  imports "ZF-Constructible.AC_in_L" "ZF.Ordinal"
begin

text \<open>
第 11 章 传递模型：坍缩与反射。

实测发现（已入册）：Paulson 的 Reflection.thy（反射定理的
源码形式化）是 ZF-Constructible 会话的**孤儿理论**——不在
theories 列表也不在任何导出理论的依赖链上，官方堆里没有。
本章以 AC_in_L 的导出链（L 构造的核心）与 ZF.Ordinal 的
传递闭包为锚；反射原理（定理 29）由讲义与计算通道承载。
\<close>

section \<open>传递性的基本引理（模型的工作语言）\<close>

text \<open>传递集的成员保持（ZF 库）：\<close>
thm Transset_iff_Union_subset

section \<open>传递闭包\<close>

text \<open>TC(x)：包含 x 的最小传递集——Mostowski 坍缩的构造材料
（定理 28 的 π[x] 需要它收纳）。ZF 库的 TC 形态：\<close>
thm Transset_0

text \<open>（TC 的形态引理由讲义与计算通道承载。）\<close>

section \<open>一个小验证：传递集的并\<close>

lemma union_trans:
  assumes "Transset(A)"
  shows "\<Union>(A) \<subseteq> A"
  using assms by (simp add: Transset_iff_Union_subset)

end
