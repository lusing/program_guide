theory Forcing
  imports "ZF-Constructible.AC_in_L" "ZF.Ordinal"
begin

text \<open>第 90 章 · 力迫基本理论与 CH/AC 独立性（冯琦第二卷 §3.1-3.3）。
本章机器化三件：定义 3.1/3.4/3.5 的抽象偏序-滤子-泛型骨架（定理 3.1
相遇链的记账半边）、泛型的对角避让（例 3.3 的抽象形态）、反链经零填充
单射进全函数空间（ccc 有限计数的抽象骨架）。力迫关系与力迫定理
（定义 3.7-3.16、定理 3.2-3.5）、Cohen 实数与加 ℵ₂ 个子集
（§3.2）、完全嵌入与 AC 独立性（§3.3）由讲义承载。\<close>

section \<open>定义 3.1/3.4/3.5：偏序、滤子、泛型的抽象骨架\<close>

text \<open>P 是条件集，leq(x,y) 读作「x 比 y 强」（书里记 x \<le> y）。
三条公理即定义 3.1：最大元 1、自反、传递。\<close>

locale forcing_poset =
  fixes P :: i
  fixes one :: i
  fixes leq :: "i \<Rightarrow> i \<Rightarrow> o"
  assumes oneP: "one \<in> P"
  assumes one_max: "\<lbrakk>x \<in> P\<rbrakk> \<Longrightarrow> leq(x, one)"
  assumes leq_refl: "\<lbrakk>x \<in> P\<rbrakk> \<Longrightarrow> leq(x, x)"
  assumes leq_trans: "\<lbrakk>leq(x, y); leq(y, z)\<rbrakk> \<Longrightarrow> leq(x, z)"

context forcing_poset
begin

text \<open>向上闭包：滤子定义的第一款（定义 3.4）在 leq 传递下的直接后果。\<close>

lemma up_closed_step:
  assumes xF: "x \<in> F" and xy: "leq(x, y)"
  shows "\<exists>z \<in> F. leq(z, y)"
  using xF xy by blast

text \<open>定理 3.1 的相遇链：pseq 是递归造出的条件链（每步用稠密集的
选择函数延长），step 是它的两条记账：p_(k+1) 落在第 k 个稠密集
D(k) 中，且比 p_k 强。把一切被某 p_k 延拓的条件收集成 meetF，
则 meetF 与每个 D(k) 相遇——定理 3.1「可数个稠密集同时被相遇」
的记账半边；另一半天真地算出泛型 h = \<Union>F 后被对角集
D_h 避开（见下一节的 diagonal_avoid）。\<close>

definition meetF :: "i \<Rightarrow> i" where
  "meetF(pseq) \<equiv> {x \<in> P. \<exists>k \<in> nat. leq(pseq`k, x)}"

lemma meetF_hits:
  fixes pseq :: i and D :: i
  assumes step: "\<And>k. k \<in> nat \<Longrightarrow> pseq`succ(k) \<in> D`k \<and> leq(pseq`succ(k), pseq`k)"
    and pk: "\<And>k. k \<in> nat \<Longrightarrow> pseq`k \<in> P"
    and kN: "k \<in> nat"
  shows "D`k \<inter> meetF(pseq) \<noteq> 0"
proof -
  from step [OF kN] have h1: "pseq`succ(k) \<in> D`k" by simp
  from pk [OF nat_succI [OF kN]] have pP: "pseq`succ(k) \<in> P" .
  from leq_refl [OF pP]
  have exj: "\<exists>j \<in> nat. leq(pseq`j, pseq`succ(k))"
  proof (rule bexI)
    show "succ(k) \<in> nat" by (rule nat_succI [OF kN])
  qed
  from exj pP have "pseq`succ(k) \<in> meetF(pseq)"
    unfolding meetF_def by auto
  with h1 show ?thesis by blast
qed

end

section \<open>例 3.3 的对角避让：泛型不属于地基\<close>

text \<open>G 是泛型分支（nat 上的 0/1 序列），bs 是地基分支的序列。
若 G 与每个 b_k 恰在坐标 k 相反，则 G 不等于任何 b_k——
「力迫扩张中有新实数」的全部内容。flip 是坐标取补的抽象。\<close>

locale diagonal_avoid =
  fixes G :: i
  fixes bs :: i
  fixes flip :: "i \<Rightarrow> i"
  assumes diff_at: "\<And>k. k \<in> nat \<Longrightarrow> flip(bs`k`k) = G`k"
    and flip_neq: "\<And>x. x \<in> 2 \<Longrightarrow> flip(x) \<noteq> x"
    and bs_val: "\<And>k. k \<in> nat \<Longrightarrow> bs`k \<in> nat \<rightarrow> 2"
    and G_val: "G \<in> nat \<rightarrow> 2"

context diagonal_avoid
begin

lemma G_not_in_bs:
  assumes kN: "k \<in> nat"
  shows "G \<noteq> bs`k"
proof
  assume eq: "G = bs`k"
  from bs_val [OF kN] and kN have valk: "bs`k`k \<in> 2"
    by (rule apply_funtype)
  from diff_at [OF kN] and eq have "flip(bs`k`k) = bs`k`k" by simp
  with flip_neq [OF valk] show False by simp
qed

end

section \<open>ccc 的抽象骨架：反链经零填充单射进全函数空间\<close>

text \<open>compat 是相容谓词，phi 是零填充（未定义坐标补 0）。
唯一公理：相冲条件的填充不同。由此，两两相冲的 A 经 phi 保持
相异——Fn(n,2) 的反链至多 2^n 个的论证骨架（例 3.3 ccc 证明：
不可数族中必有同长度同值的两支，故必相容）。\<close>

locale compat_fill =
  fixes compat :: "i \<Rightarrow> i \<Rightarrow> o"
  fixes phi :: "i \<Rightarrow> i"
  fixes B :: i
  assumes incompat_fill: "\<And>f g. \<not>compat(f, g) \<Longrightarrow> phi(f) \<noteq> phi(g)"
  assumes phi_range: "\<And>f. phi(f) \<in> B"

context compat_fill
begin

definition antichain :: "i \<Rightarrow> o" where
  "antichain(A) \<equiv> \<forall>f \<in> A. \<forall>g \<in> A. f \<noteq> g \<longrightarrow> \<not>compat(f, g)"

lemma antichain_phi_distinct:
  assumes aA: "antichain(A)"
    and fg: "f \<in> A" "g \<in> A" "phi(f) = phi(g)"
  shows "f = g"
proof (rule ccontr)
  assume ne: "f \<noteq> g"
  from aA and fg(1,2) and ne have nc: "\<not>compat(f, g)"
    unfolding antichain_def by auto
  from incompat_fill [OF nc] show False using fg(3) by simp
qed

end

section \<open>§3.1-3.3 讲义锚点\<close>

text \<open>P 名字与检查名（定义 3.7/3.8）、力迫语言 FL_P（定义 3.9）、
力迫扩张 M[G]（定义 3.11）、外部力迫关系（定义 3.12）与内部三重
递归定义（定义 3.13-3.16）、力迫定理（真值引理与可定义性引理，
§3.1.5）由讲义与 Lean/Coq/Agda/计算通道的有限样品承载；
Cohen 实数 c = \<Union>G 与加 2^(ℵ₂) 个子集（§3.2）、
完全嵌入与对称子模型（§3.3：AC 的独立性）亦由讲义承载。\<close>

end
