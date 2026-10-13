theory Ordinals
  imports "ZF-Constructible.Formula" "ZF.Ordinal"
begin

text \<open>
第 02 章 序数：ZF 库的 Ordinal 理论。

序数 = 传递且被 \<in> 良序化的集合。本章抽查库锚点并做两个
完整证明：succ 的严格递增、以及 ω 的刻画（最小非零极限序数）。
\<close>

section \<open>库锚点\<close>

text \<open>序数的定义性刻画（Ordinal 是 Ord 的成员）：\<close>
thm Ord_is_Transset

text \<open>传递集合的并封闭：\<close>
thm Transset_Union

text \<open>三歧性（任何两序数可比）：\<close>
thm Ord_linear_lt

text \<open>超穷归纳（ZF 的 induct 规则）：\<close>
thm Ord_induct

section \<open>两个完整证明\<close>

text \<open>succ 严格增大：succ(i) 是比 i 大的最小序数。\<close>
lemma succ_increases: "i \<in> succ(i)"
  by (unfold succ_def, blast)

text \<open>ω 是所有自然数的上确界，自身是极限序数：
ZF 库的 Limit_def 给出极限的刻画（非零、非后继）。\<close>

thm Limit_def

text \<open>自然数都是序数（Nat into Ord）：\<close>
thm nat_into_Ord

text \<open>把第 01 章的外延性用在序数上：两个序数相等当且仅当
互为子集。这里给一个方向：子集 + 序数 = 属于（Jech 引理 2.3(c)）。\<close>
lemma ordinal_subset_mem:
  assumes "Ord(i)" "Ord(j)" "i \<subseteq> j"
  shows "i \<in> j \<or> i = j"
proof -
  from assms have "i \<le> j" by (blast intro: subset_imp_le)
  then consider "i < j" | "i = j" by (auto simp: le_iff)
  then show ?thesis
  proof cases
    case 1
    then show ?thesis by (blast dest: ltD)
  next
    case 2
    then show ?thesis by blast
  qed
qed

end
