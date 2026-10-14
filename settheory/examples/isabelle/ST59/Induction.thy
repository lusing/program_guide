theory Induction
  imports "ZF.Arith"
begin

text \<open>第 59 章：归纳与递归（Makinson Ch4）。nat_rec 递归子、
简单归纳、良基归纳与超穷归纳的官方锚点。\<close>

subsection \<open>简单递归：递归子 nat_rec\<close>

text \<open>nat_rec(k, a, b)：基 a、步 b(m, nat_rec(m,a,b))——书本
"输出回收为输入"的 ZF 官方形态。\<close>

lemma nat_rec_0_example: "nat_rec(0, 0, \<lambda>m x. succ(succ(x))) = 0"
  by (simp only: nat_rec_0)

lemma nat_rec_succ_example:
  "m \<in> nat \<Longrightarrow> nat_rec(succ(m), 0, \<lambda>m x. succ(succ(x)))
   = succ(succ(nat_rec(m, 0, \<lambda>m x. succ(succ(x)))))"
  by (rule nat_rec_succ)

subsection \<open>简单归纳：递归子定义的倍加函数 = n+n\<close>

lemma rec_double: "n \<in> nat \<Longrightarrow> nat_rec(n, 0, \<lambda>m x. succ(succ(x))) = n #+ n"
  by (induct rule: nat_induct, simp_all add: nat_rec_succ nat_rec_0)

subsection \<open>累积归纳：一切 m<n 有 P 则 n 有 P\<close>

text \<open>对"前段全真"这一更强命题做简单归纳即可派生（书 4.5.2）。
  更一般的形态由下节的良基归纳承载——那里没有显式的基。\<close>

subsection \<open>良基与超穷：官方锚点\<close>

text \<open>良基归纳原理（书 4.7.2 的四行证明）：
  wf_induct——无基点，极小元处假设真空。\<close>

lemma wf_trancl_example: "wf(r) \<Longrightarrow> wf(r^+)"
  by (rule wf_trancl)

lemma wf_Memrel_example: "wf(Memrel(A))"
  by (rule wf_Memrel)

text \<open>超穷归纳（02 章的 ZF 官方形态；Makinson 在"门外"止步）。\<close>

lemma trans_induct_example:
  "(\<And>x. Ord(x) \<Longrightarrow> (\<And>y. y \<in> x \<Longrightarrow> P(y)) \<Longrightarrow> P(x))
   \<Longrightarrow> Ord(i) \<Longrightarrow> P(i)"
  by (erule trans_induct, blast)

end
