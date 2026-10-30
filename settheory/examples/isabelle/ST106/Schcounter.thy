theory Schcounter
  imports "ZF.Nat" "ZF.equalities"
begin

text \<open>第 106 章：有限 SCH 账簿的集论核（确定性规则链，沿 103-105 章纪律）。
本体（定义 2.12-2.19、引理 2.13-2.21、定理 2.12 Gitik-Magidor-Woodin）
留在正文。\<close>

text \<open>跳档点集与 GCH 点集互斥。\<close>

definition jumpP :: "i \<Rightarrow> o" where
  "jumpP(b) \<equiv> b = 1"

definition gchP :: "i \<Rightarrow> o" where
  "gchP(b) \<equiv> b = 0"

lemma gch_jump_disjoint: "gchP(b) \<Longrightarrow> \<not> jumpP(b)"
  unfolding gchP_def jumpP_def
proof (rule notI)
  assume h1: "b = 0" and h2: "b = 1"
  from h1 h2 have "0 = 1" by (rule subst)
  thus False by simp
qed

text \<open>更小节点全满足：初始段全 GCH。\<close>

definition allGCH :: "i \<Rightarrow> o" where
  "allGCH(A) \<equiv> \<forall>b\<in>A. gchP(b)"

lemma allGCH_empty: "allGCH(0)"
  unfolding allGCH_def by simp

lemma allGCH_cons: "allGCH(A) \<Longrightarrow> gchP(b) \<Longrightarrow> allGCH(cons(b, A))"
  unfolding allGCH_def
proof (rule ballI)
  fix x
  assume hA: "\<forall>b\<in>A. gchP(b)" and hb: "gchP(b)" and hx: "x \<in> cons(b, A)"
  show "gchP(x)"
  proof (cases "x = b")
    case True
    with hb show ?thesis by simp
  next
    case False
    with hx have "x \<in> A" by simp
    with hA show ?thesis by (rule bspec)
  qed
qed

text \<open>位移支配样本（引理 2.20 影子的序骨架）：
n ≤ succ(n)（对自然数）且经传递放大。\<close>

lemma le_succ_step: "n \<in> nat \<Longrightarrow> n \<le> succ(n)"
proof -
  assume hn: "n \<in> nat"
  have hOrd: "Ord(n)" by (rule nat_into_Ord) (rule hn)
  have hle: "n \<le> n" by (rule le_refl) (rule hOrd)
  show ?thesis unfolding le_succ_iff by (rule disjI1 [OF hle])
qed

lemma le_shift_sample:
  assumes h: "b \<le> n" and hs: "n \<le> succ(n)"
  shows "b \<le> succ(n)"
  by (rule le_trans [OF h hs])

end
