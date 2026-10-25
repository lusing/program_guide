theory Constructible
  imports "ZF-Constructible.AC_in_L" "ZF.Ordinal"
begin

text \<open>第 87 章 · 可构造宇宙 L 与一般连续统假设（冯琦第二卷 §2.1）。
本章机器化三件：定义 2.1/引理 2.1 在 Isabelle/ZF Constructible 里的
官方锚点（Lset 三方程 + DPow）；哥德尔基本集合运算（定义 2.4）的
计算样品；定理 2.9 的后承 AC 在 L 中（AC_in_L 锚点）。
凝聚化引理与 GCH（定理 2.10/2.11）库中无——由讲义承载。\<close>

section \<open>定义 2.1 与引理 2.1 的官方锚点\<close>

text \<open>Lset 的三条层次方程正是定义 2.1：L_0 = 0、
L_{succ(i)} = DPow(L_i)（DPow = 带参数可定义子集之全体 = 冯琦的
集合运算 𝒟）、极限层取并；Lset_mono 是引理 2.1(1)；Ord_in_Lset
是引理 2.1(4) 的 Ord ⊆ L 方向；DPow_subset_Pow 即 𝒟(M) ⊆ P(M)：\<close>

thm Lset_0 Lset_succ Lset_Union Lset_mono Ord_in_Lset
thm DPow_subset_Pow

lemma DPow_0: "DPow(0) = {0}"
proof (rule equalityI)
  show "DPow(0) \<subseteq> {0}"
  proof (rule subsetI)
    fix X assume XD: "X \<in> DPow(0)"
    then have "X \<subseteq> 0" by (rule DPow_imp_subset)
    then have "X = 0" by (simp add: subset_empty_iff)
    then show "X \<in> {0}" by simp
  qed
next
  have z: "0 \<in> DPow(0)" by (rule empty_in_DPow)
  show "{0} \<subseteq> DPow(0)"
  proof (rule subsetI)
    fix X assume "X \<in> {0}"
    then have "X = 0" by simp
    with z show "X \<in> DPow(0)" by simp
  qed
qed

text \<open>于是 L_1 = {0}，L_2 = {0,{0}} = 2：可构造层次在有限层与
V 完全重合（引理 2.1(3)）的最小样品——空结构上唯一的可定义子集是
空集，单点结构上两个子集全部可定义。\<close>

lemma Lset_1_eq: "Lset(succ(0)) = {0}"
  by (simp add: Lset_succ Lset_0 DPow_0)

text \<open>层次增长的引擎是引理 1.15(1)：传递集合的每个成员都是自己的
可定义子集的成员（y \<in> x \<subseteq> M 时，公式 v\<sub>0\<subseteq> v\<sub>1\<subseteq> 带参数 x 在 M 上
定义出 x 本身）——机器形态即 elem_subset_in_DPow：\<close>

lemma trans_M_subset_DPow:
  assumes tr: "Transset(M)"
  shows "M \<subseteq> DPow(M)"
proof (rule subsetI)
  fix x assume xM: "x \<in> M"
  from tr have un: "\<Union>(M) \<subseteq> M" by (simp add: Transset_iff_Union_subset)
  have xsub: "x \<subseteq> M"
  proof (rule subsetI)
    fix y assume yx: "y \<in> x"
    from xM have hx: "x \<subseteq> \<Union>(M)" by (rule Union_upper)
    from hx yx have hy: "y \<in> \<Union>(M)" by (rule subsetD)
    from un hy show "y \<in> M" by (rule subsetD)
  qed
  from xM xsub show "x \<in> DPow(M)" by (rule elem_subset_in_DPow)
qed

text \<open>（库注：本机 ZF-Constructible 堆的 Formula 是较老版本，
DPow_insert 不在堆中，DPow({0}) 的逐元素展开因此改走
elem_subset_in_DPow 一侧；L_2 = {0,{0}} = 2 的完整计算由
Python/Julia/Prolog 通道的 def_closure 承载。）\<close>

section \<open>定义 2.4 的哥德尔基本集合运算样品\<close>

text \<open>十个哥德尔基本集合运算里，六个就是 ZF 库的原生运算；
引理 2.5（可定义性）断言它们全部由 Δ₀ 表达式定义，因此对传递
结构绝对。这里验证三件计算恒等式。\<close>

definition G1 :: "[i,i] \<Rightarrow> i" where "G1(x,y) \<equiv> {x,y}"
definition G4 :: "[i,i] \<Rightarrow> i" where "G4(x,y) \<equiv> x - y"
definition G5 :: "[i,i] \<Rightarrow> i" where "G5(x,y) \<equiv> x \<inter> y"
definition G6 :: "i \<Rightarrow> i" where "G6(x) \<equiv> \<Union>(x)"
definition G7 :: "i \<Rightarrow> i" where "G7(x) \<equiv> domain(x)"
definition G8 :: "i \<Rightarrow> i" where "G8(x) \<equiv> converse(x)"

text \<open>并对（G1）之后取并集（G6）恰是二元并：\<close>

lemma G6_pair: "G6(G1(a,b)) = a \<union> b"
  by (simp add: G6_def G1_def)

text \<open>差与交的吸收律（两件平凡但值得点名的代数事实）：\<close>

lemma G5_absorb: "G5(x,x) = x"
  by (simp add: G5_def)

lemma G4_diff_0: "G4(x, 0) = x"
  by (simp add: G4_def)

section \<open>定理 2.9 的后承：AC 在 L 中\<close>

text \<open>定理 2.9（哥德尔）给 L 一个 Σ₁ 可定义的秩序；AC_in_L.thy 是
这一路线的官方机器形态——典范序 L_r 良序化每个 Lset(i)，
从而每个可构造集合可良序化（冯琦推论：V=L 蕴含 AC）：\<close>

thm Nat_Times_Nat.well_ord_L_r
thm L_implies_AC

section \<open>凝聚化引理与 GCH（定理 2.10/2.11 讲义）\<close>

text \<open>凝聚化引理（定理 2.10）：设 α > ω 是极限序数，X ⊆ L_α 且
(X,∈) ≺₁ (L_α,∈)。则 (X,∈) 是外延结构（L_α 中两个不同集合的差别
被 Σ₁ 公式见证，搬到 X 中），依第一卷传递化定理（定理 I.1.97）
坍缩为传递结构 (M,π)；由 Σ₁-初等性，(V=L) 在 M 中成立，
而 x ∈ L 在 KP 中是 Σ₁ 的，逐层比较得 M = L_β（β = M ∩ Ord ≤ α）；
并且 π 在 X 的传递子集上是恒等，π(x) ≤_L x（用 <_L 定义在所有
极限层上的 Σ₁ 一致性做最小反例归纳）。

GCH（定理 2.11）：在 V=L 下，任给 A ⊆ κ，取充分大的极限 λ 使
A ∈ L_λ，令 M 为包含 L_κ ∪ {A} 的最小 Σ₁ 初等子模型（引理 2.21，
|M| = κ）；凝聚化给 M ≅ L_β，|β| = κ，故 β < κ⁺ 而 A ∈ L_{κ⁺}。
于是 P(κ) ⊆ L_{κ⁺}，2^κ ≤ |L_{κ⁺}| = κ⁺（引理 2.1(6)），
配 Cantor 下界得 2^κ = κ⁺。∎\<close>

end
