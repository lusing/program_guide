theory T51_fixpoints
  imports Main
begin

section \<open>51.1 Knaster--Tarski：归纳定义的数学引擎\<close>

text \<open>第 31 章说 @{verbatim "inductive"} 造"最小关系"、第 35 章说
@{verbatim "partial_function"} 是"最小不动点 + 容许性"。它们的数学
原型都在这一章：完备格上的 **Knaster--Tarski 定理**——单调函数的
最小不动点 @{verbatim "lfp"} 与最大不动点 @{verbatim "gfp"} 存在，
且有完整刻画。Main（@{verbatim "Inductive.thy"}）已经给了全套官方
版本；我们**从定义出发重新证明**，名字前缀 @{verbatim "kt_"}，
官方名在每条后面注明。\<close>

ML \<open>writeln "==== 51 开始 ===="\<close>

subsection \<open>51.2 舞台与定义\<close>

text \<open>官方定义（原文）：@{verbatim "lfp f = Inf {u. f u \<le> u}"}
——所有**前不变点**（@{verbatim "f u \<le> u"}）的下确界；
@{verbatim "gfp"} 对偶地取后不变点的上确界：\<close>

thm lfp_def gfp_def

subsection \<open>51.3 KT 下界与最大性：lfp 的两个"最小"面相\<close>

text \<open>@{verbatim "lfp_lowerbound"} 的复刻（kt_ 前缀）。
**不需要单调性**——纯粹是 Inf 的下界性质。注意引理放在
@{verbatim "context complete_lattice"} 块**外面**用
@{verbatim "'a::complete_lattice"} sort 声明：实测 locale 内
@{verbatim "unfolding lfp_def"} 后 @{verbatim "order_antisym"}
无法应用（动机不明），块外一切正常——又一个"实测>直觉"：\<close>

lemma kt_lowerbound:
  fixes f :: "'a::complete_lattice \<Rightarrow> 'a"
  shows "f A \<le> A \<Longrightarrow> lfp f \<le> A"
  unfolding lfp_def by (rule Inf_lower) simp

lemma kt_greatest:
  fixes f :: "'a::complete_lattice \<Rightarrow> 'a"
  shows "(\<And>u. f u \<le> u \<Longrightarrow> A \<le> u) \<Longrightarrow> A \<le> lfp f"
  unfolding lfp_def by (rule Inf_greatest) simp

subsection \<open>51.4 KT 不动点定理：单调则 lfp 恰是 f 的不动点\<close>

text \<open>夹逼两方向（官方 @{verbatim "lfp_fixpoint"} 原文复刻，
仅在外层补 sort）。上界方向用 @{verbatim "Inf_greatest"} + 单调传递；
下界方向的关键一步：@{verbatim "f (lfp f)"} 自己也是前不变点
（@{verbatim "f (f ?a) \<le> f ?a"}），于是进了 @{verbatim "?H"}
集合：\<close>

lemma kt_fixpoint:
  fixes f :: "'a::complete_lattice \<Rightarrow> 'a"
  assumes "mono f"
  shows "f (lfp f) = lfp f"
  unfolding lfp_def
proof (rule order_antisym)
  let ?H = "{u. f u \<le> u}"
  let ?a = "Inf ?H"
  show "f ?a \<le> ?a"
  proof (rule Inf_greatest)
    fix x
    assume "x \<in> ?H"
    then have "?a \<le> x" by (rule Inf_lower)
    with \<open>mono f\<close> have "f ?a \<le> f x" ..
    also from \<open>x \<in> ?H\<close> have "f x \<le> x" ..
    finally show "f ?a \<le> x" .
  qed
  show "?a \<le> f ?a"
  proof (rule Inf_lower)
    from \<open>mono f\<close> and \<open>f ?a \<le> ?a\<close> have "f (f ?a) \<le> f ?a" ..
    then show "f ?a \<in> ?H" ..
  qed
qed

text \<open>展开形式（官方 @{verbatim "lfp_unfold"}）：\<close>

lemma kt_unfold:
  fixes f :: "'a::complete_lattice \<Rightarrow> 'a"
  shows "mono f \<Longrightarrow> lfp f = f (lfp f)"
  by (rule kt_fixpoint [symmetric])

subsection \<open>51.5 对偶：gfp 与余归纳的接口\<close>

text \<open>@{verbatim "gfp"} 的官方刻画：@{verbatim "gfp_unfold"}、
@{verbatim "coinduction"}。第 26 章的共归纳原理在数学上就是
@{verbatim "gfp"} 的最大性（官方 @{verbatim "gfp_upperbound"}）。
全部白给，不必重证：\<close>

thm gfp_upperbound gfp_unfold

subsection \<open>51.6 连接：inductive 与 partial_function 的引擎\<close>

text \<open>把链条接起来（全部官方事实，打印为证）：

  - @{verbatim "inductive"} 定义的谓词是 @{verbatim "lfp"}
    （作用在谓词格上）；它的 @{verbatim ".induct"} 规则来自
    @{verbatim "lfp_induct"}——不动点上的归纳；
  - @{verbatim "partial_function"} 用的是**链完备偏序**上的
    最小不动点（@{verbatim "Complete_Partial_Order"} 理论，
    @{verbatim "ccpo"} 类），容许性（@{verbatim "admissible"}）
    代替单调性保证 Kleene 链收敛；
  - @{verbatim "datatype"}/@{verbatim "codatatype"} 的最小/最大
    不动点在**类型层**（BNF 的有界性替代完备格）——同一首定理
    的三种编曲。\<close>

thm lfp_induct

subsection \<open>51.7 坑位清单（实测）\<close>

text \<open>1. @{verbatim "lfp_lowerbound"} **不需要 mono**；忘写
   @{verbatim "mono"} 的错误通常出在 @{verbatim "lfp_unfold"} 一侧
   （那里必须要）。
2. 复刻官方证明时 @{verbatim "Inf_lower/Inf_greatest"} 的方向
   极易写反：Inf 是**最大下界**——@{verbatim "Inf_lower"} 给
   "Inf 在每个成员之下"，@{verbatim "Inf_greatest"} 给
   "比所有成员都小的 ≤ Inf"。
3. @{verbatim "lfp"} 生活在 @{verbatim "complete_lattice"} 类：
   谓词格（@{verbatim "'a \<Rightarrow> bool"}）自动是实例，
   @{verbatim "inductive"} 走这条线；但任意偏序未必完备——
   @{verbatim "partial_function"} 换 @{verbatim "ccpo"} 就是为了
   网开一面。
4. @{verbatim "gfp"} 与 @{verbatim "lfp"} 的对偶不完美：
   @{verbatim "gfp_unfold"} 也要 mono，但 @{verbatim "coinduction"}
   的实用形态（双相似）比 @{verbatim "lfp_induct"} 多一层
   relation 侧写。\<close>

thm kt_lowerbound kt_greatest kt_fixpoint kt_unfold

ML \<open>writeln "==== 51 结束 ===="\<close>

end
