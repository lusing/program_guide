theory Ordinals
  imports "ZF.Ordinal" "ZF.Univ" "ZF.Nat"
begin

text \<open>第 71 章：序数与累积层次（冯琦 §1.7）。定义 1.57 内禀三条件的
ZF 官方化身：可比较性（定理 1.50）、元素更小（命题 1.19）、ω 是极限
（例 1.20）、V 塔与秩（定义 1.64/1.66；RK 的序数恒等）。\<close>

subsection \<open>定理 1.50：可比较性（三择一）\<close>

text \<open>Ord\_linear\_lt 是 obtains 形式的三分律，逐案 blast 收尾——
冯琦 Φ₁（∈-连通）+ Φ₂（良基）的官方浓缩。\<close>

lemma comparability:
  assumes "Ord(i)" "Ord(j)" shows "i < j \<or> i = j \<or> j < i"
  using assms
  apply (rule_tac i = i and j = j in Ord_linear_lt)
   apply blast+
  done

subsection \<open>命题 1.18/1.19：后继、元素与塔性\<close>

lemma succ_ordinal [TC]: "Ord(i) \<Longrightarrow> Ord(succ(i))"
  by (rule Ord_succ)

lemma elem_smaller: "\<lbrakk> Ord(i); j \<in> i \<rbrakk> \<Longrightarrow> Ord(j) \<and> j < i"
  by (blast intro: ltI lt_Ord)

text \<open>序数的元素是严格更小的序数——"序数是序数之塔"（命题 1.19）。\<close>

subsection \<open>例 1.20：ω（nat）是非零极限序数\<close>

lemma omega_limit: "Limit(nat)"
  by (rule Limit_nat)

text \<open>nat 即冯琦的 ω：ZF 传统把第一个无穷序数记作 nat。\<close>

subsection \<open>定义 1.64：累积层次 V 塔\<close>

text \<open>Vfrom(A,0) = A；Vfrom(A,succ(i)) = A \<union> Pow(Vfrom(A,i))；
极限处取并——定义 1.64 的三条装配线逐字对应（Vset 即 A=0 的塔）。\<close>

lemma V_0: "Vset(0) = 0"
  by (rule Vfrom_0)

lemma V_succ: "Vset(succ(i)) = Pow(Vset(i))"
  by (rule Vset_succ)

lemma V_limit: "Limit(i) \<Longrightarrow> Vset(i) = (\<Union>y\<in>i. Vset(y))"
  by (rule Limit_Vfrom_eq)

subsection \<open>定义 1.66 与命题 1.21：秩函数\<close>

text \<open>Vset\_Ord\_rank\_iff：b \<in> Vset(i) \<longleftrightarrow> rank(b) \<lt> i——
"每个集合都住在某个 V\_α 里、且住在第 rank+1 层"。秩的序数恒等
（RK(α) = α，RK(n) = n 的推广）由 rank\_of\_Ord 给出。\<close>

lemma rank_ordinals: "Ord(i) \<Longrightarrow> rank(i) = i"
  by (rule rank_of_Ord)

lemma mem_Vset_iff_rank: "Ord(i) \<Longrightarrow> b \<in> Vset(i) \<longleftrightarrow> rank(b) < i"
  by (rule Vset_Ord_rank_iff)

end
