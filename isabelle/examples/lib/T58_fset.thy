theory T58_fset
  imports "HOL-Library.Disjoint_FSets"
begin

section \<open>58.1 FSet：把「有限」编进类型\<close>

text \<open>第 57 章里 fmdom 的类型是 @{typ "'a fset"}。本章正式讲它。
普通 @{typ "'a set"} 可以无穷，所以「有限性」每次都要挂一个
@{term finite} 前提；@{typ "'a fset"} 则是「有限集合」的子类型
（与 fmap 同款的 typedef + Lifting 流水线），有限性由类型**保证**，
所有接收 fset 的操作都不必再带有限性前提。本章还讲两个配套理论：
@{theory "HOL-Library.Disjoint_Sets"}（普通集合上的两两不相交族）
与 @{theory "HOL-Library.Disjoint_FSets"}（fset 版的二元不相交，
以及它与 fmap 并运算的关系）。\<close>

ML \<open>writeln "==== 58 开始 ===="\<close>

subsection \<open>58.2 构造：字面量、finsert、fset_of_list\<close>

text \<open>空集是 @{term "{||}"}，插入用 @{const finsert}，字面量
@{verbatim "{|x, y, z|}"} 是它的嵌套语法糖。从列表造集用
@{const fset_of_list}（重复元素被吞掉）：\<close>

value "{|1, 2, 2, 3|} :: nat fset"
value "fset_of_list [1::nat, 2, 2, 3]"
value "finsert 4 ({|1, 2, 3|} :: nat fset)"
value "finsert 2 ({|1, 2, 3|} :: nat fset)"

text \<open>求值结果打印成 @{verbatim "Abs_fset {…}"}——typedef 内部
构造子，表示「普通集合的有限包装」；往普通集合的投影叫
@{const fset}。想要可阅读的列表形式，用
@{const sorted_list_of_fset}（要求 @{class linorder}）：\<close>

value "fset ({|3, 1, 2|} :: nat fset)"
value "sorted_list_of_fset ({|3, 1, 2|} :: nat fset)"

subsection \<open>58.3 属于、量词与集合代数\<close>

text \<open>属于关系是双竖线 @{term "x |\<in>| A"}。有限量词
@{verbatim "\<forall>x|\<in>|A. P x"} / @{verbatim "\<exists>x|\<in>|A. P x"} 展开为
@{const fBall}/@{const fBex}，即对 @{term "fset A"} 的普通量词：\<close>

value "2 |\<in>| ({|1, 2, 3|} :: nat fset)"
value "\<forall>x|\<in>|({|2, 4, 6|} :: nat fset). even x"
value "\<exists>x|\<in>|({|1, 3, 4|} :: nat fset). even x"

text \<open>并 @{term "A |\<union>| B"}、交 @{term "A |\<inter>| B"}、差
@{term "A |-| B"}、包含 @{term "A |\<subseteq>| B"} 一应俱全；
它们是 lattice 类族的实例，@\{class semilattice_inf\} 一类定律
直接可用。@{class finite} 类型上还有全集 @{term fUNIV} 与补集：\<close>

value "({|1, 2|} :: nat fset) |\<union>| {|2, 3|}"
value "({|1, 2|} :: nat fset) |\<inter>| {|2, 3|}"
value "({|1, 2, 3|} :: nat fset) |-| {|2|}"
value "{|1|} |\<subseteq>| ({|1, 2|} :: nat fset)"
value "(fUNIV :: bool fset) |-| {|True|}"

subsection \<open>58.4 像、绑定、幂集与大并\<close>

text \<open>@{term "f |`| A"}（@{const fimage}）是函数像；@{const fbind}
是单子式的「先像后并」；@{const fPow} 取幂集（元素仍是 fset）；
@{const ffUnion} 把一族 fset 并起来。@{const fthe_elem} 从单元素集
取出那个元素（非单元素时行为未指定，证明上谨慎使用）：\<close>

value "((+) 1) |`| ({|1, 2, 3|} :: nat fset)"
value "fbind ({|1, 2|} :: nat fset) (\<lambda>n. {|n, n + 10|})"
lemma fPow_bool:
  "fPow ({|True, False|}) = {| {||}, {|True|}, {|False|}, {|True, False|} |}"
  including fset.lifting by transfer auto
value "ffUnion ({| {|1::nat, 2|}, {|2, 3|}, {|5|} |})"
value "fthe_elem ({|42|} :: nat fset)"

subsection \<open>58.5 ffilter、ffold 与 fsum\<close>

text \<open>@{const ffilter} 按谓词筛；@{const ffold} 是有限折叠
（参数顺序：运算、初值、集合）。在此之上库为每个交换幺半群装了
大算子，加法的那个叫 @{const fsum}——注意它是**前缀**常量
（@{verbatim "fsum f A"}），没有 @{term sum} 那样的绑定记号：\<close>

value "ffilter even ({|1, 2, 3, 4|} :: nat fset)"
value "fsum id ({|1, 2, 3, 4|} :: nat fset)"
value "fsum (\<lambda>x. x * x) ({|1, 2, 3|} :: nat fset)"

text \<open>@{const ffold} 的计算等式只在 @{const comp_fun_commute} 语境成立
（任意运算不能保证与插入顺序无关），所以裸 @{verbatim value} 会退化成
「在整个类型上折叠」而报 @{class finite} 类错误；对 @{term "(+) 0"}
这种交换幺半群，正解就是用 @{const fsum}，两者对加法一致：\<close>

lemma ffold_plus_is_fsum:
  "ffold (+) 0 A = fsum id (A :: nat fset)"
proof -
  have cfc: "comp_fun_commute (%(x::nat) y. x + y)"
    by standard (simp add: fun_eq_iff ac_simps)
  show ?thesis
  proof (induct A rule: fset_induct_stronger)
    case empty
    show ?case by (simp add: comp_fun_commute.ffold_empty cfc fsum.F.rep_eq)
  next
    case (insert x A)
    show ?case
      by (simp add: comp_fun_commute.ffold_finsert cfc fsum.F.rep_eq finsert.rep_eq
          insert.hyps)
  qed
qed

lemma "ffold (+) 0 ({|1, 2, 3, 4|} :: nat fset) = 10"
  by (simp add: ffold_plus_is_fsum fsum.F.rep_eq finsert.rep_eq)

text \<open>@{const fcard} 是基数。有限性已在类型里，不用再带
@{term finite} 前提；与普通 @{const card} 一样，交非空时要用
「容斥」，不相交时直接相加
（@{thm fcard_funion_disjoint [no_vars]}）：\<close>

value "fcard ({|1, 2, 2, 3|} :: nat fset)"

text \<open>@{const fPow} 没有注册代码等式（幂集依赖枚举整个元素类型，
代码层只对 @{class finite} 类型才有意义），所以它的结论写成引理；
基数走 transfer 回普通集合，用 @{thm card_Pow [no_vars]}：\<close>

lemma "fcard (fPow ({|True, False|})) = 4"
  including fset.lifting by transfer (simp add: card_Pow)

subsection \<open>58.6 fMin 与 fMax\<close>

text \<open>在 @{class linorder} 元素上，@{const fMin}/@{const fMax} 取
最小/最大元素（空集上无定义）。它们由 @{const Min}/@{const Max}
经 Lifting 得到，@\{thm fMax_in [no_vars]\} 保证最大元素确实在
集合里：\<close>

value "fMax ({|3, 7, 1, 2|} :: nat fset)"
value "fMin ({|3, 7, 1, 2|} :: nat fset)"

lemma "fMax ({|3, 7, 1, 2|} :: nat fset) = 7"
  by simp

subsection \<open>58.7 Disjoint_Sets：两两不相交的集合族\<close>

text \<open>@{theory "HOL-Library.Disjoint_Sets"} 处理的是**普通集合**。
最底层的二元谓词 @{const disjnt}：@{term "disjnt A B"} 就是
@{term "A \<inter> B = {}"}。在此之上，@{const disjoint} 定义为
@{term "pairwise disjnt"}——族中任意两个**不同**成员互不相交：

@{thm [display] disjoint_def [no_vars]}

@{const disjoint_family_on} 则按指标集说话：带指标的族
@{term "A i"} 在指标集 @{term I} 上两两不相交。先看求值：\<close>

value "disjnt {1::nat, 2} {3, 4}"
value "disjnt {1::nat, 2} {2, 3}"
value "disjoint {{1::nat, 2}, {3}, {4}}"
value "disjoint {{1::nat, 2}, {2}}"

text \<open>一个带指标的不相交族：把 0 到 5 按奇偶分成两族。
引入规则 @{thm disjoint_family_on_insert [no_vars]} 是增量证明的
抓手；这里直接用定义加 auto：\<close>

lemma parity_partition:
  "disjoint_family_on (\<lambda>b. if b then {0::nat, 2, 4} else {1, 3, 5}) UNIV"
  by (auto simp: disjoint_family_on_def)

text \<open>不相交族最常用的推论是**基数可加**：并的基数等于各成员基数
之和（有限情形 @{thm card_UN_disjoint' [no_vars]} 的特例）。
把奇偶两族并起来：\<close>

lemma "card ({0::nat, 2, 4} \<union> {1::nat, 3, 5}) =
         card {0::nat, 2, 4} + card {1::nat, 3, 5}"
  by (simp add: card_Un_disjoint)

subsection \<open>58.8 Disjoint_FSets：fset 版与 fmap 的交换律\<close>

text \<open>@{const fdisjnt} 是 @{const disjnt} 的 fset 孪生：
@{thm fdisjnt_alt_def [no_vars]}。它的规则族与集合版平行
（@{thm fdisjnt_union_right [no_vars]} 等），并且对插入敏感——
@{thm fdisjnt_insert [no_vars]} 要求新元素不在另一边。

一个与第 57 章直接呼应的结论：第 57 章说 @{term "m ++\<^sub>f n"} 一般
**右表优先**、不交换；但如果两张表的**定义域不相交**，就没有谁
覆盖谁的问题，并运算于是交换：

@{thm [display] fmadd_disjnt [no_vars]}\<close>

value "fdisjnt ({|1, 2|} :: nat fset) {|3, 4|}"
value "fdisjnt ({|1, 2|} :: nat fset) {|2, 3|}"

lemma disjnt_maps_commute:
  "let m = fmap_of_list [(1::nat, ''a'')];
       n = fmap_of_list [(2, ''b'')]
   in fdisjnt (fmdom m) (fmdom n) \<and> m ++\<^sub>f n = n ++\<^sub>f m"
  by (simp add: fmadd_disjnt fdisjnt_alt_def fmupd_reorder_neq)

text \<open>反过来，定义域有重叠时交换律失效——右表仍然覆盖左表：\<close>

lemma overlap_maps_noncommute:
  "fmap_of_list [(1::nat, ''a'')] ++\<^sub>f fmap_of_list [(1, ''b'')] \<noteq>
   fmap_of_list [(1, ''b'')] ++\<^sub>f fmap_of_list [(1, ''a'')]"
proof -
  have l: "fmlookup (fmap_of_list [(1::nat, ''a'')] ++\<^sub>f fmap_of_list [(1, ''b'')]) 1 = Some ''b''"
    by simp
  have r: "fmlookup (fmap_of_list [(1::nat, ''b'')] ++\<^sub>f fmap_of_list [(1, ''a'')]) 1 = Some ''a''"
    by simp
  show ?thesis
  proof (rule notI)
    assume e: "fmap_of_list [(1::nat, ''a'')] ++\<^sub>f fmap_of_list [(1, ''b'')] =
               fmap_of_list [(1, ''b'')] ++\<^sub>f fmap_of_list [(1, ''a'')]"
    have k: "fmlookup (fmap_of_list [(1::nat, ''b'')] ++\<^sub>f fmap_of_list [(1, ''a'')]) 1 = Some ''b''"
      by (subst e[symmetric]) (fact l)
    with r show False by simp
  qed
qed

subsection \<open>58.9 一个完整小案例：基数可加的划分\<close>

text \<open>把本节各件缝合：用 fset 表达 0..5 的一个三划分，验证
「两两不相交 + 覆盖全集 ⇒ 基数之和 = 总基数」。@{const fsum}
版的可加性走折叠；这里用普通 @{const sum} 配合有限集族表述，
两种写法对照：\<close>

definition parts :: "nat fset fset" where
  "parts = {| {|0, 3|}, {|1, 4|}, {|2, 5|} |}"

lemma parts_partition:
  "pairwise fdisjnt (fset parts)"
  by (simp add: parts_def pairwise_def fdisjnt_alt_def)

lemma parts_union: "ffUnion parts = {|0::nat, 1, 2, 3, 4, 5|}"
  by (auto simp: parts_def fset_eq_iff)

lemma "fcard (ffUnion parts) = 6"
  by (simp add: parts_union fcard.rep_eq)

subsection \<open>58.10 坑位清单（实测）\<close>

text \<open>
1. 三套字面量别混：fset 是双竖线 @{verbatim "{| |}"}，multiset 是
   @{verbatim "{# #}"}（第 45 章），普通集合是 @{verbatim "{ }"}。
2. fset 的 @{verbatim value} 打印成 @{verbatim "Abs_fset {…}"} 是
   正常现象（typedef 构造子）；要看列表用
   @{const sorted_list_of_fset}。
3. @{const fsum} 是前缀常量 @{verbatim "fsum f A"}，没有
   @{verbatim "SUM x:A. …"} 绑定记号；后者是普通集合的
   @{const sum}。
4. 与第 57 章同源的代码边界：fset 操作在代码层 unfold 成普通集合，
   凡实现依赖「枚举整个类型」的操作（典型：fmap 上的
   @{const size}/@{const fmimage}、普通集合族的 @{const Pow}，以及
   fset 版的 @{const fPow}）在无穷类型上不能 @{verbatim value}，
   @{const fPow} 甚至干脆没有代码等式；fset 的字面量运算、
   @{const fcard}、@{const fsum} 走折叠等式可求值，但裸
   @{const ffold} 对任意运算没有计算式（只在
   @{const comp_fun_commute} 语境成立），加法折叠要用
   @{const fsum}。
5. @{const fPow} 的结果类型是 @{typ "'a fset fset"}（两层 fset），
   别只套一层。
6. @{const disjoint}（普通集合族）与 @{const fdisjnt}（fset 二元）
   不在一个层：前者来自 Disjoint_Sets，后者来自 Disjoint_FSets；
   fset 族的「两两不相交」要写 @{term "pairwise fdisjnt (fset A)"}
   （@{const pairwise} 吃普通集合，先投影 @{const fset}）。
7. @{const disjnt} 与 @{const disjoint} 不是一回事：前者是**二元**
   谓词 @{term "disjnt (A :: 'a set) B = (A \<inter> B = {})"}；后者才是族上的 pairwise
   性质（没有一个大写的 Disjoint 常量，别凭印象写）。
8. @{const fMin}/@{const fMax}/@{const fthe_elem} 在空集上都没有
   好行为，使用前先用非空前提（如 @{term "A \<noteq> {||}"}）守住。
9. @{term "A |-| B"} 是 fset 差；fmap 没有这个记号，fmap 删除用
   @{const fmdrop} 一族（第 57 章）。
10. 想把 fset 当 Main 集合用就投影 @{term "fset A"}；反向
    @{const fset_of_list} 从列表入、@{const sorted_list_of_fset}
    从有序列表出，这三个转换是 fset 世界与 Main 集合/列表库的
    全部通关口。
\<close>

ML \<open>writeln "==== 58 结束 ===="\<close>

end
