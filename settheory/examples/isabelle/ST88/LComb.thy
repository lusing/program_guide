theory LComb
  imports "ZF-Constructible.AC_in_L" "ZF.Ordinal"
begin

text \<open>第 88 章 · L 中的组合原理与弱紧基数（冯琦第二卷 §2.1.4-2.1.5）。
本章机器化一件：Jensen 苏斯林树构造（定理 2.12）的封口引擎——被封口
的反链在一切更高层保持极大（性质 (4)），以抽象前缀树 locale 承载。
钻石原理（定理 2.13/2.14）与弱紧的语言刻画（定理 2.15/2.16）由讲义
承载，Lean/Coq/Agda/计算通道给有限与 ω-尺度的引擎样品。\<close>

section \<open>封口引擎：抽象前缀树上的核心归纳\<close>

text \<open>R 是层间的延拓关系（前缀序），T 是逐层的节点集。
两条公理：树步进（新一层的每个节点延拓前层节点）与 R 的传递性——
它们是定理 2.12 性质 (4) 归纳的全部输入。\<close>

locale prefix_tree =
  fixes R :: "i \<Rightarrow> i \<Rightarrow> o"
  fixes T :: "i \<Rightarrow> i"
  assumes R_trans: "\<lbrakk>R(x, y); R(y, z)\<rbrakk> \<Longrightarrow> R(x, z)"
  assumes step: "\<lbrakk>n \<in> nat; t \<in> T(succ(n))\<rbrakk> \<Longrightarrow> \<exists>s \<in> T(n). R(s, t)"

context prefix_tree
begin

text \<open>反链 A 在层 T(n) 上封口：每个节点延拓 A 的成员。\<close>

definition sealed :: "i \<Rightarrow> i \<Rightarrow> o" where
  "sealed(A, n) \<equiv> \<forall>t \<in> T(n). \<exists>a \<in> A. R(a, t)"

text \<open>定理 2.12 性质 (4)：封口一旦完成便永久保持。
封口层每个节点延拓 A 的成员；此后每层节点延拓前层节点，
R 传递，于是 A 在所有更高层保持极大——Jensen 构造中
「极大性被未来永久保持」的全部内容。\<close>

lemma sealed_persists:
  assumes h0: "k \<in> nat" and h1: "sealed(A, succ(k))"
  shows "\<forall>n \<in> nat. succ(k) \<le> n \<longrightarrow> sealed(A, n)"
proof (rule ballI)
  fix n assume nN: "n \<in> nat"
  from nN show "succ(k) \<le> n \<longrightarrow> sealed(A, n)"
  proof (induct rule: nat_induct)
    case 0
    thus ?case by simp
  next
    case (succ n)
    show ?case
    proof
      assume hn: "succ(k) \<le> succ(n)"
      show "sealed(A, succ(n))"
      proof (cases "succ(k) = succ(n)")
        case True
        thus ?thesis using h1 by simp
      next
        case False
        hence hle: "succ(k) \<le> n" using hn False by (simp add: le_succ_iff)
        from succ.hyps(2) hle have hprev: "sealed(A, n)" by simp
        show ?thesis unfolding sealed_def
        proof (rule ballI)
          fix t assume tT: "t \<in> T(succ(n))"
          from step [OF succ.hyps(1) tT] obtain s where sT: "s \<in> T(n)" and sR: "R(s, t)"
            by blast
          from hprev sT have "\<exists>a \<in> A. R(a, s)" unfolding sealed_def by blast
          then obtain a where aA: "a \<in> A" and aR: "R(a, s)" by blast
          from R_trans [OF aR sR] and aA
          show "\<exists>a \<in> A. R(a, t)" by blast
        qed
      qed
    qed
  qed
qed

end

text \<open>（locale 内的 blast 只面向单点存在实例化，目标已由 ballI/obtain
钉死，不会展开集合运算；这是 F5 坑位「blast 三失控形态」之外的
安全用法。）\<close>

section \<open>定理 2.12-2.16 讲义锚点\<close>

text \<open>定理 2.12（Jensen）：ZF + V=L \<turnstile> 存在苏斯林规范树。
构造：高度 ω₁ 的 0-1-序列树，极限层 α 取 <_L 最小的与 α 等高的
极大反链 A_α，B_α = 每个节点经它可及的最小等高树枝，T_α = 这些
树枝的并。反证：不可数极大反链 A 的 C_A = {α | A\<inter>T\<upharpoonright>α 是
T\<upharpoonright>α 的极大反链} 是无界闭集；取可数 hull M \<prec> (L_{ω₂},\<in>)
包含全部构造数据，α = M\<inter>ω₁ \<in> C_A；凝聚化（定理 2.10）坍缩
M 为 L_β，绝对性给出 A\<inter>T\<upharpoonright>α = A_α——但 A_α 被构造永久
封口，矛盾。

定理 2.13：ZFC \<turnstile> \<diamond> \<longrightarrow> CH（钻石序列把每个实数送到它的初始段
出现的时刻，实数注入 ω₁）。
定理 2.14（Jensen）：ZF + V=L \<turnstile> \<diamond>：递归 (S_α, C_α)，极限步取
<_L 最小的「局部反例对」；若全局反例 (X,C) 存在，取最小者、造
可数 hull、凝聚化后 (X\<inter>α, C\<inter>α) 恰是 (S_α, C_α) 而 α \<in> C，
矛盾——与定理 2.12 同一个模式。

定义 2.19/2.20：语言 L_{κ,ω}（<κ 长度析取合取）与 L_{κ,κ}（再加
<κ 长度量词）；弱紧致性 = 势 \<le> κ 的语句集有模型当且仅当每个
势 <κ 的子集有模型。
定理 2.15：κ 弱紧 \<Longrightarrow> L_{κ,κ} 弱紧（斯科伦化 + 高度 κ 的二元
分叉树 + 树特性取树枝 + 项模型）；反之 κ 不可达且 L_{κ,ω} 弱紧
\<Longrightarrow> κ 弱紧（把树编码成语句集）。
定理 2.16：κ 弱紧 \<Longrightarrow> (1) (V_κ,\<in>,U) 有传递初等扩张含 κ；
(2) A\<subseteq>κ 且每个初始段可构造则 A\<in>L；(3) 弱紧在 L 中保持——
树枝 b 的每个初始段 b\<inter>α\<in>L，由 (2) 得 b\<in>L。\<close>

end
