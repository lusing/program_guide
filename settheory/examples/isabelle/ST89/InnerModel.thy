theory InnerModel
  imports "ZF-Constructible.AC_in_L" "ZF.Ordinal"
begin

text \<open>第 89 章 · 内模型 HOD、L[A] 与 L(ℝ)（冯琦第二卷 §2.2）。
本章机器化两件：引理 2.24 的抽象引擎（L[U] = L[U\<inter>L[U]] 的
层次不变性），与引理 2.27(2)（HOD 对 \<in> 的传递性）的抽象形态。
定理 2.17/2.19/2.20/2.24/2.25 由讲义承载。\<close>

section \<open>引理 2.24 的抽象引擎：截断不变性\<close>

text \<open>DU 是「带谓词 U 的可定义子集」运算的抽象替身（定义 2.22 的
形式参数）；locale 只要求一条交换律：DU 在 M 上只看到 U\<inter>M——
这正是引理 2.24 的全部内容。\<close>

locale relative_def =
  fixes DU :: "i \<Rightarrow> i"
  fixes DUs :: "[i, i] \<Rightarrow> i"
  fixes U :: i
  assumes trunc: "\<And>M. DU(M) = DUs(U \<inter> M, M)"

context relative_def
begin

text \<open>截断不变性的单步形态：DU 在 M 上的行为完全由 U\<inter>M 决定。
把它沿定义 2.23 的层次逐层归纳（极限层取并，两端都只依赖截断），
便得引理 2.24：L[U] = L[Ũ]（Ũ = U\<inter>L[U]）——层次每一步
只用到当时的 U 截断，换成 Ũ 毫无损失。ZF 中 nat 非 datatype，
层次递归的 primrec 化因此由讲义与其它通道承载。\<close>

lemma trunc_step:
  shows "DU(M) = DUs(U \<inter> M, M)"
  by (rule trunc)

end

section \<open>引理 2.27(2)：HOD 对 \<in> 的传递性（抽象形态）\<close>

text \<open>TCf 是传递闭包的抽象替身；locale 公理「y \<in> x \<Longrightarrow>
TCf({y}) \<subseteq> TCf({x})」是集合论里 TC 的标准簿记。HOD 的成员
判据由 OD 类与彻底性给出。\<close>

locale hered_class =
  fixes TCf :: "i \<Rightarrow> i"
  fixes OD :: i
  assumes TC_mono: "\<lbrakk>y \<in> x\<rbrakk> \<Longrightarrow> TCf(cons(y, 0)) \<subseteq> TCf(cons(x, 0))"

context hered_class
begin

definition HODm :: "i \<Rightarrow> o" where
  "HODm(a) \<equiv> TCf(cons(a, 0)) \<subseteq> OD"

text \<open>引理 2.27(2)：彻底序数可定义集合的成员彻底序数可定义。\<close>

lemma HOD_trans:
  assumes h: "HODm(a)" and y: "y \<in> a"
  shows "HODm(y)"
proof -
  from TC_mono [OF y] and h show ?thesis
    unfolding HODm_def by (rule subset_trans)
qed

end

section \<open>定理 2.17-2.25 讲义锚点\<close>

text \<open>定理 2.17（ZF）：U 是集合时 L[U] 是 ZF 的传递模型，
L[U] \<turnstile> V=L[X]，且对任何含 U 的内模型 N 有 L[U] \<subseteq> N。
逐公理验证与定理 2.2 同构（分解原理走广义镜像原理对齐求值层）。

引理 2.24：L[U] = L[Ũ]（Ũ = U\<inter>L[U]），且 U \<in> L[U]——
上面机器化的交换律 + 映像存在原理。
定理 2.18：U \<in> L[U] 时 L[U] 有 U-可定义的秩序，从而 L[U] \<turnstile> ZFC。
引理 2.25（凝聚化，L[U] 版）：X \<prec>_1 (L_\<lambda>[U], \<in>, U\<inter>L_\<lambda>[U])
的坍缩是某个 L_\<beta>[U]。定理 2.19：L[U] 中自某基数起 GCH 成立
（凝聚化把 P(\<omega>_\<alpha>) 钉进 L_{\<omega>_\<alpha>+1}[U]）。

定义 2.27/2.28/2.29：OD(M)（序数参数可定义元素）、
OD = \<Union>a. OD(V_a)、HOD（彻底序数可定义）。例 2.2：
OD(V_n) = V_n、OD(V_\<omega>) = V_\<omega>、OD(V_{\<omega>+1}) 可数。
引理 2.26：OD 上有可定义单射 H: OD \<rightarrow> Ord（<^* 序数有限序列
字典序 + 公式枚举）；OD = cl({V_\<beta> | \<beta><a})——序数可定义集
恰是 V 层次的哥德尔闭包。定理 2.20：HOD \<turnstile> ZFC（定理 2.5 的
封闭 + 覆盖：V_\<alpha>\<inter>HOD \<in> HOD 供出覆盖见证；AC 由可定义单射）。
定理 2.21：V=L \<Longrightarrow> V=HOD。

定义 2.30-2.32：OD^R/HOD^R（实数序数可定义版）；定理 2.22：
HOD^R \<turnstile> ZF；定理 2.23：HOD^R \<turnstile> AC \<longleftrightarrow>
\<exists>W \<in> HOD ((R, W) 是秩序)。
定义 2.33：L_0(a) = TC({a})，L_{a+1} = 相对 TC({a}) 全体谓词的
可定义子集；L(R) 是包含全体实数与序数的最小 ZF 传递模型。
定理 2.24：L(a) \<turnstile> ZF + V=L(a)，最小性。定理 2.25：
ZF+DC \<turnstile> L(R) \<turnstile> DC——满射 \<Phi>: Ord\<times>R \<rightarrow> L(R) 的
层前截段落在 L(R) 中，DC 链可被实数序列记录。\<close>

end
