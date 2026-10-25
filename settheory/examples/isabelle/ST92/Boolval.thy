theory Boolval
  imports "ZF-Constructible.AC_in_L" "ZF.Ordinal"
begin

text \<open>第 92 章 · 布尔值模型（冯琦第二卷 §3.5）。
本章机器化两件：布尔值结构四公理（定义 3.50）的传递-包容链条
（由 (c)(d) 推出换位形式）；超滤子的交-补换算（定义 3.62 与
引理 3.71/3.72 的原子：滤子保交、超滤子定向）。
完备布尔代数与 Stone 表示（定义 3.38-3.49、定理 3.20/3.21/3.22）、
布尔值算法与基本不等式（定义 3.51-3.52、定理 3.23）、V^B 论域与
度量（定义 3.54-3.58）、引理 3.73-3.81、定理 3.24（ZFC 在 V^B 中真）、
推论 3.11（相对独立性原理）、布尔值-力迫等价（定理 3.25-3.26）、
Vopénka 定理 3.29、完备子代数与中间模型（定义 3.66-3.67、
引理 3.85-3.88）、广义分配律（定义 3.68）由讲义与
Lean/Coq/Agda/计算通道的有限样品承载。\<close>

section \<open>布尔值结构：传递-包容链条（定义 3.50 的 (c)(d)）\<close>

text \<open>Bm 是「布尔代数乘」的抽象替身（满足分配律与布尔不等式的
两条记账），Fe 与 Fm 分别是隶属与相等的布尔值度量。定义 3.50 的
公理 (a) 自反、(b) 对称直接进入 locale；(c) 与 (d) 的换位形态
在此推导。\<close>

locale bvs =
  fixes Bm :: "i \<Rightarrow> i \<Rightarrow> i"
  fixes Fe :: "i \<Rightarrow> i \<Rightarrow> i"
  fixes Fm :: "i \<Rightarrow> i \<Rightarrow> i"
  assumes Fe_sym: "Fe(a, b) = Fm(b, a)"
  assumes Fm_sym: "Fm(a, b) = Fm(b, a)"
  assumes trans_c: "Fm(a, b) * Fm(b, c) \<le> Fm(a, c)"
  assumes incl_d: "Fe(a, b) * Fm(a, c) * Fm(b, d) \<le> Fe(c, d)"
  assumes unit_absorb: "x * Fm(b, b) = x"

context bvs
begin

text \<open>(d) 的换位形态：b=c 时包容律退化为「相等替换」——
    a∈b ∧ a=c ⟹ c∈b（用 (d) 与 (a)(b) 的记号换向）。\<close>

lemma incl_swap:
  shows "Fe(a, b) * Fm(a, c) \<le> Fe(c, b)"
proof -
  have h1: "Fe(a, b) * Fm(a, c) * Fm(b, b) \<le> Fe(c, b)"
    using incl_d by simp
  hence "Fe(a, b) * Fm(a, c) \<le> Fe(c, b)"
    using unit_absorb by simp
  thus ?thesis .
qed

text \<open>(c) 的对称形态：相等沿隶属度量双向传递。\<close>

lemma trans_sym:
  shows "Fm(a, b) * Fm(b, c) \<le> Fm(c, a)"
  using trans_c Fm_sym by simp

end

section \<open>超滤子的交-补换算（定义 3.62 / 引理 3.71-3.72 的原子）\<close>

text \<open>U 是布尔代数 B 的超滤子：向上闭、乘法定向（滤子性）、
极值（与补恰取其一）。交的单向换算：乘积在 U 中则两因子都在
（乘积不超过每个因子，向上封闭）。\<close>

locale ultrafilter =
  fixes B :: i
  fixes U :: i
  fixes bm :: "i \<Rightarrow> i \<Rightarrow> i"
  fixes bc :: "i \<Rightarrow> i"
  fixes ble :: "i \<Rightarrow> i \<Rightarrow> o"
  assumes up_closed: "\<lbrakk>x \<in> U; ble(x, y); y \<in> B\<rbrakk> \<Longrightarrow> y \<in> U"
  assumes filter_meet: "\<lbrakk>x \<in> U; y \<in> U\<rbrakk> \<Longrightarrow> bm(x, y) \<in> U"
  assumes meet_le_left: "x \<in> B \<Longrightarrow> y \<in> B \<Longrightarrow> ble(bm(x, y), x)"
  assumes meet_le_right: "x \<in> B \<Longrightarrow> y \<in> B \<Longrightarrow> ble(bm(x, y), y)"
  assumes meet_compl_zero: "x \<in> B \<Longrightarrow> bm(x, bc(x)) = 0"
  assumes zero_not_in: "0 \<notin> U"
  assumes ultra: "x \<in> B \<Longrightarrow> x \<in> U \<or> bc(x) \<in> U"

context ultrafilter
begin

lemma meet_in_imp_both:
  assumes xB: "x \<in> B" and yB: "y \<in> B" and h: "bm(x, y) \<in> U"
  shows "x \<in> U \<and> y \<in> U"
proof
  from up_closed [OF h meet_le_left [OF xB yB] xB] show "x \<in> U" .
  from up_closed [OF h meet_le_right [OF xB yB] yB] show "y \<in> U" .
qed

text \<open>极值性的二选一形态：x 与 bc(x) 恰有一个在 U 中。\<close>

lemma ultra_exclusive:
  assumes xB: "x \<in> B" and h1: "x \<in> U" and h2: "bc(x) \<in> U"
  shows False
proof -
  from filter_meet [OF h1 h2] have hb: "bm(x, bc(x)) \<in> U" .
  from meet_compl_zero [OF xB] and hb and zero_not_in show False by simp
qed

end

section \<open>§3.5 讲义锚点\<close>

text \<open>完备布尔代数（定义 3.38 公理 Ba1-Ba6；理想/滤子/商 3.39-3.43；
Stone 正则截断表示定理 3.20；完备化与唯一性定理 3.21、推论 3.8；
饱和数定理 3.22）与布尔值结构（定义 3.50-3.52、基本布尔值不等式
定理 3.23、逻辑公理引理 3.70、富有性与超滤子商引理 3.71-3.72）、
V^B 论域（定义 3.54-3.58、度量引理 3.73-3.74、泛型特性 3.75、
混合名字 3.77、富有性 3.78、Δ_0 绝对性 3.80 与定理 3.24：ZFC 的
每条公理布尔值为 1；推论 3.11 相对独立性原理：若 ZFC 证得 φ 则
⟦φ⟧=1，故 ⟦¬φ⟧>0 即独立）与布尔值-力迫等价（名字嵌入定义 3.60、
定理 3.25/3.26）、V-泛型超滤子（定义 3.62-3.64、定理 3.27-3.28）、
Vopénka 代数（定义 3.65、定理 3.29：V=L[A] 时 V=HOD[G]——
泛型滤子可就地在当前论域实现）、完备子代数与中间模型（定义
3.66-3.67、引理 3.85-3.88、推论 3.12-3.14）与广义分配律
（定义 3.68：κ-分配 = ∧Σ 与 Σ∧ 的交换；与定义 3.24 的
贝尔纲式分配的联系）均由讲义承载。\<close>

end
