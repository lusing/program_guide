theory T67_order_fixpoint
  imports "HOL-Library.Bourbaki_Witt_Fixpoint" "HOL-Library.Order_Continuity"
    "HOL-Library.Extended_Nat" "HOL-Library.Lattice_Constructions"
    "HOL-Library.Lub_Glb" "HOL-Library.Complemented_Lattices"
    "HOL-Library.Complete_Partial_Order2"
begin

unbundle lattice_syntax

section \<open>67.1 Bourbaki_Witt_Fixpoint：无拓扑的不动点定理\<close>

text \<open>Knaster–Tarski（第 51 章）要完备格，Bourbaki–Witt 只要
「链有 lub 的偏序」（chain-complete）加一个**递增**算子
（@{term "x \<le> f x"}，不需要单调性！）。
@{theory "HOL-Library.Bourbaki_Witt_Fixpoint"} 的 locale
 @{verbatim bourbaki_witt_fixpoint} 收 @{verbatim lub}/@{verbatim leq}/
 @{verbatim f} 三参数，构造 @{verbatim "iterates_above a"}
（从 a 出发，f 步进 + 链上取 lub 的归纳闭包），定义
 @{verbatim "fixp_above a = lub (iterates_above a)"}，
结论是 @{verbatim fixp_above_unfold}：@{verbatim "fixp_above a = f (fixp_above a)"}。

实例化到 @{typ enat}（61 章）：完备线序、@{const eSuc} 递增：\<close>

ML \<open>writeln "==== 67 开始 ===="\<close>

interpretation bw: bourbaki_witt_fixpoint Sup "{(x, y::enat). x \<le> y}" eSuc
proof
  show "Partial_order {(x, y::enat). x \<le> y}"
    by (auto simp: partial_order_on_def Field_def preorder_on_def
         intro!: refl_onI transI antisymI intro: order_refl)
next
  fix M :: "enat set" and z
  assume "M \<in> Chains {(x, y). x \<le> y}" "M \<noteq> {}" "\<And>x. x \<in> M \<Longrightarrow> (x, z) \<in> {(x, y). x \<le> y}"
  then show "(Sup M, z) \<in> {(x, y). x \<le> y}" by (simp add: Sup_least)
next
  fix M :: "enat set" and x
  assume "M \<in> Chains {(x, y). x \<le> y}" "x \<in> M"
  then show "(x, Sup M) \<in> {(x, y). x \<le> y}" by (simp add: Sup_upper)
next
  fix M :: "enat set"
  assume "M \<in> Chains {(x, y). x \<le> y}" "M \<noteq> {}"
  show "Sup M \<in> Field {(x, y::enat). x \<le> y}" by (auto simp: Field_def)
next
  fix x :: enat
  assume "x \<in> Field {(x, y). x \<le> y}"
  show "(x, eSuc x) \<in> {(x, y). x \<le> y}" by (simp add: eSuc_plus_1[symmetric])
qed

text \<open>四条义务恰好是「完备格 + 递增」的展开。结论读出：
从 0 出发的不动点是 @{term "\<infinity>"}——eSuc 的唯一不动点，
迭代永远不到头，极限（Sup）收在无穷：\<close>

lemma bw_fixpoint: "bw.fixp_above 0 = \<infinity>"
proof -
  have zero: "0 \<in> Field {(x, y::enat). x \<le> y}" by (auto simp: Field_def)
  have fixeq: "bw.fixp_above 0 = eSuc (bw.fixp_above 0)"
    by (rule bw.fixp_above_unfold[OF zero])
  show ?thesis
  proof (cases "bw.fixp_above 0")
    case (enat n)
    with fixeq show ?thesis by (simp add: eSuc_enat)
  next
    case infinity
    then show ?thesis by simp
  qed
qed

text \<open>证明形状值得记：先用 @{verbatim fixp_above_unfold} 拿到
不动点方程，再按 @{typ enat} 两种形态分情形——有限形态与方程
矛盾（@{const eSuc} 单射且 @{term "n \<noteq> Suc n"}），只剩
@{term "\<infinity>"}。库末尾还有 @{verbatim fixp_above_conv_while}：
这个不动点恰好是 @{const while} 循环「迭代到不变」的语义——
不动点理论与程序语义的接口就在这里。\<close>

section \<open>67.2 Order_Continuity：连续映射保持极限\<close>

text \<open>@{theory "HOL-Library.Order_Continuity"} 定义
@{const sup_continuous}（@{verbatim "F (SUP i. M i) = (SUP i. F (M i))"}
对单调序列）与对偶的 @{const inf_continuous}——斯科特连续性
的可数形式。内建 intro 规则集 @{verbatim order_continuous_intros}
（常函数、恒等、复合、sup/inf 保连续）；61 章 enat 上的
@{thm sup_continuous_eSuc [no_vars]} 是它的用户：\<close>

lemma "sup_continuous (eSuc :: enat \<Rightarrow> enat)"
  using sup_continuous_eSuc[OF sup_continuous_id] by (simp add: id_def)

text \<open>「连续 + 单调」组合出 Kleene 不动点链的收敛——这是把
67.1 的抽象不动点算到具体值的通道。\<close>

section \<open>67.3 Lub_Glb：老式确界接口\<close>

text \<open>@{theory "HOL-Library.Lub_Glb"} 是分析库出现前的确界语言：
载集 R 内、S 的上界 @{const isUb}、最小上界 @{const isLub}
（及对偶 @{const isLb}/@{const isGlb}），辅助谓词
@{term "S *<= x"}/@{term "x <=* S"}。与现代 @{const Sup}/
@{const Inf}（完备格类）的分工：这套接口**不要求**整个类型
完备，确界存在性是逐集合证的。闭区间上确界是端点：\<close>

lemma isLub_interval: "isLub UNIV {0..(1::real)} 1"
  by (auto simp: isLub_def leastP_def isUb_def setle_def setge_def)

text \<open>（展开定义后：1 是上界显然；任何上界 x 因 @{term "1 \<in> {0..1}"}
而 ≥ 1。）两条关键引理：@{thm isLub_unique [no_vars]}（线序上
唯一）与 @{thm isLub_le_isUb [no_vars]}（最小性）。\<close>

section \<open>67.4 Lattice_Constructions：给类型加顶底与拍平\<close>

text \<open>@{theory "HOL-Library.Lattice_Constructions"} 提供三个
「类型构造子级」的格手术：@{typ "'a bot"}（加底元素
@{verbatim Bot}）、@{typ "'a top"}（加顶 @{verbatim Top}）、
@{typ "'a flat_complete_lattice"}（拍平：底 < 所有值 < 顶，
值之间不可比——完全格）。包装后原序继续可用
（@{verbatim Value} 注人）：\<close>

lemma "Bot \<le> (x :: nat flat_complete_lattice)"
  by simp

lemma flat_two_values:
  "Value a \<le> (z :: 'a flat_complete_lattice) \<Longrightarrow> Value b \<le> z \<Longrightarrow> a \<noteq> b \<Longrightarrow> z = Top"
  by (rule greater_than_two_values)

text \<open>第二条是拍平格的标志性事实：两个不同的值若共同有上界，
那上界只能是顶——「平」的直接推论。拍平格是抽象解释
（abstract interpretation）里常量传播格的标准件。\<close>

section \<open>67.5 Complemented_Lattices：补格\<close>

text \<open>@{theory "HOL-Library.Complemented_Lattices"} 定义
@{class complemented_lattice}（有界格 + 补 @{verbatim "- x"} +
两条补公理 @{thm inf_compl_bot [no_vars]}/对偶），并证
@{class boolean_algebra} 是它的实例。补格上补惟一
（@{verbatim compl_unique} 一族）：\<close>

lemma compl_meet_bot: "x \<sqinter> - x = (\<bottom> :: 'a :: complemented_lattice)"
  by simp

lemma bool_double_compl: "- (- (x::bool)) = x"
  by simp

section \<open>67.6 Complete_Partial_Order2：ccpo 的工具箱\<close>

text \<open>@{theory "HOL-Library.Complete_Partial_Order2"} 是 Main 的
@{class ccpo}（第 35 章 @{command partial_function} 的语义底座）
的补充包：定点归纳 @{verbatim fixp_induct} 的更多形态、
容许谓词（@{verbatim ccpo.admissible}）的构造规则、迭代逼近
（@{verbatim iterates}）的代数。它没有新的「定义性」内容，
全是让 35 章那种「函数不动点」证明更好写的工具——读
partial_function 生成的 @{verbatim ".mono"}/@{verbatim ".fixp"} 引理
时会发现它们的证明都收编在这里。\<close>

section \<open>67.7 坑位清单（实测）\<close>

text \<open>
1. Bourbaki–Witt 的 locale 参数是**关系集合** @{verbatim leq}
   （@{typ "('a \<times> 'a) set"}）加显式 @{verbatim lub} 算子，
   不是类实例——实例化时 @{term Sup}/@{term "{(x,y). x \<le> y}"}
   这样喂。
2. @{verbatim "iterates_above"} 的闭包含**极限步**（链的 lub），
   不只是 f 的有限迭代——所以 fixp_above 能一步到 @{term "\<infinity>"}
   这类超限点。
3. @{verbatim Partial_order}（大写，关系集合上的性质）与
   @{class order} 类不是一个层：@{verbatim "Partial_order r ⟷
   partial_order_on (Field r) r"}。
4. fact 名字撞 Isar 关键字会报外层语法错（实测 @{verbatim fix}
   撞 @{command fix}，「proposition expected, end-of-input」）——
   起名避开 Isar 关键词表。
5. Lub_Glb 的第一个参数是**载集**不是关系：
   @{term "isLub UNIV S x"} 读作「x 是 S 在全类型上的确界」；
   别传序关系进去。
6. @{verbatim bot}/@{verbatim top}/@{verbatim flat_complete_lattice}
   三个类型的构造子同名（@{verbatim Value}/@{verbatim Bot}/
   @{verbatim Top}），同堂时写全类型标注。
7. @{const sup_continuous} 的定义里是「单调序列的像的 SUP」，
   不是任意集合——范畴里叫 countable-cocontinuous；别的文献
   的「连续」口径可能更宽。
8. 补格的 @{verbatim "- x"} 是一元减号与补共享记号
   （@{class uminus}），数值类型上读作相反数、补格上读作补，
   看类型分辨。
9. enat 的 @{const eSuc} 递增性写法是 @{thm eSuc_plus_1 [no_vars]}
   反向用（@{verbatim "eSuc_plus_1[symmetric]"}）——直接
   @{verbatim simp} 不够时记得对称形态。
10. Complete_Partial_Order2 与 Bourbaki_Witt 是两条互补线：
    前者要单调性给归纳工具，后者不要单调性但没归纳原则；
    选哪条看你的 f 是否单调。
\<close>

ML \<open>writeln "==== 67 结束 ===="\<close>

end
