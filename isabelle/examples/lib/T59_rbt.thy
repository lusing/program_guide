theory T59_rbt
  imports "HOL-Library.Tree" "HOL-Library.RBT_Set" "HOL-Library.RBT_Mapping"
begin

section \<open>59.1 裸二叉树：Tree\<close>

text \<open>@{theory "HOL-Library.Tree"} 给出库中最基础的二叉树：两个构造子
@{term "\<langle>\<rangle>"}（空叶）与 @{term "\<langle>l, x, r\<rangle>"}（左子树、值、右子树），
外加一组递归度量和三种遍历。它本身不带任何「序」或「平衡」假设，
是所有有序树结构（包括本章红黑树）的公共底座。先造一棵三节点树：\<close>

ML \<open>writeln "==== 59 开始 ===="\<close>

definition t3 :: "nat tree" where
  "t3 = \<langle>\<langle>\<langle>\<rangle>, 1, \<langle>\<rangle>\<rangle>, 2, \<langle>\<langle>\<rangle>, 3, \<langle>\<rangle>\<rangle>\<rangle>"

value "size t3"
value "size1 t3"
value "height t3"
value "inorder t3"
value "preorder t3"
value "postorder t3"

text \<open>@{const size} 数内部节点，@{const size1} 数叶子（两者差 1，
@{thm size1_size [no_vars]}）；@{const height} 是根到最深叶子的边数。
三种遍历满足 @{thm set_inorder [no_vars]}（遍历的元素集就是
@{const set_tree}），且 @{const inorder} 与镜像互为反转
（@{thm inorder_mirror [no_vars]}）：\<close>

value "mirror t3"
value "inorder (mirror t3)"

lemma "inorder (mirror t3) = rev (inorder t3)"
  by (simp add: inorder_mirror)

text \<open>谓词 @{const bst} 判定二叉搜索树性质（左子树全小于根、右子树
全大于根，递归）；它与「中序遍历有序」互为表里
（@{thm bst_iff_sorted_wrt_less [no_vars]}）。@{const complete} 判定
「每层都满」（左右子树等高且递归完备）：\<close>

value "bst t3"
value "bst \<langle>\<langle>\<rangle>, 2::nat, \<langle>\<langle>\<rangle>, 1, \<langle>\<rangle>\<rangle>\<rangle>"
value "complete t3"

text \<open>第二行是反例：根 2 的右子树里放了 1，违反搜索树性质。
完备树有高与规模的精确关系 @{thm size_if_complete [no_vars]}；
一般树只有上界 @{thm size1_height [no_vars]}。这些定理说明
「平衡」直接决定高度、进而决定查找代价——这正是红黑树要保的东西。\<close>

section \<open>59.2 RBT_Impl：颜色、黑高与两条不变量\<close>

text \<open>红黑树的原始数据类型在 @{theory "HOL-Library.RBT_Impl"}：
颜色 @{verbatim "color = R | B"}，节点
@{verbatim "Branch color rbt key value rbt"}。这个理论是**实现层**，
作者在开头的注释里明说：应用请用包装层 @{theory "HOL-Library.RBT"}。
红黑性质拆成四个谓词：\<close>

text \<open>\begin{itemize}
\item @{const RBT_Impl.inv1}：没有相邻的红节点（红节点的两个子节点必须黑）；
\item @{const RBT_Impl.inv2}：任意节点的左右子树**黑高**相等——
  黑高 @{const RBT_Impl.bheight} 只数黑节点；
\item 根必须为黑（@{const RBT_Impl.color_of} 等于 @{verbatim B}）；
\item @{const RBT_Impl.rbt_sorted}：搜索树性质（左 < 根 < 右，
  递归，记号 @{term "l |\<guillemotleft> k"} 表示左子树所有键小于 @{term k}）。
\end{itemize}
合起来就是 @{thm RBT_Impl.is_rbt_def [no_vars]}。用求值直接看
两种违规：\<close>

value "RBT_Impl.inv1 (RBT_Impl.Branch RBT_Impl.R RBT_Impl.Empty (1::nat) ()
  (RBT_Impl.Branch RBT_Impl.R RBT_Impl.Empty 2 () RBT_Impl.Empty))"
value "RBT_Impl.inv2 (RBT_Impl.Branch RBT_Impl.B
  (RBT_Impl.Branch RBT_Impl.B RBT_Impl.Empty (1::nat) () RBT_Impl.Empty)
  2 () RBT_Impl.Empty)"

text \<open>第一行红节点带红孩子，@{const RBT_Impl.inv1} 为 @{term False}；
第二行左子树黑高 1、右子树黑高 0，@{const RBT_Impl.inv2} 为
@{term False}。这两条不变量合起来的推论是：最长根叶路径至多是最短的
两倍（路径上红不超黑），高度因此是 @{verbatim "O(log n)"}。
注意本理论只验证不变量的**保持**（每条操作一条
@{verbatim is_rbt} 定理），并没有证明高度的对数界——那在
HOL-Data_Structures 里（本教程后续批次）。\<close>

section \<open>59.3 Okasaki 插入：balance 与 paint\<close>

text \<open>插入按 Okasaki 的函数式算法实现，源码注释也这么标注。
核心是 @{const RBT_Impl.balance}：五条带红-红冲突的模式各自
做一次「旋转+换色」，其余情况原样涂黑。看一条具体求值——
左-左冲突（红节点的左孩子还是红）被旋转成根红、两子黑：\<close>

value "RBT_Impl.balance
  (RBT_Impl.Branch RBT_Impl.R
    (RBT_Impl.Branch RBT_Impl.R RBT_Impl.Empty (1::nat) () RBT_Impl.Empty)
    2 () RBT_Impl.Empty)
  3 () RBT_Impl.Empty"

text \<open>输出是 @{verbatim "Branch R (Branch B Empty 1 Empty) 2 Empty (Branch B Empty 3 Empty)"}：
冲突被消解为局部完美形状。递归插入 @{const RBT_Impl.rbt_ins} 在黑节点处
调 @{const RBT_Impl.balance}、在红节点处直接挂（红节点的父亲必然是黑，
留待上层平衡），最后 @{const RBT_Impl.rbt_insert} 用
@{const RBT_Impl.paint} 把根涂黑收尾——涂黑只增黑高，不破坏任何
不变量，这就是「根必黑」条款好维护的原因。删除比插入复杂得多
（@{const RBT_Impl.rbt_baldL}/@{const RBT_Impl.rbt_baldR} 一族
修补函数），但结构思想相同：局部修复 + 向上传递。\<close>

section \<open>59.4 RBT：typedef 抽象类型与 lookup 代数\<close>

text \<open>@{theory "HOL-Library.RBT"} 把满足 @{const RBT_Impl.is_rbt}
的树收进抽象类型 @{typ "('a::linorder, 'b) rbt"}（typedef +
Lifting，第 28/29 章的流水线再演一次）。从此**类型本身保证不变量**，
用户接触不到能破坏平衡的原始构造子；投影 @{const RBT.impl_of} 只在
证明里需要回到实现层时用。全部操作的语义都挂在偏函数
@{const RBT.lookup} 上——这就是与 Main 的 @{typ "'a \<rightharpoonup> 'b"}
世界（第 57 章）的接口。先看求值：\<close>

definition t4 :: "(nat, string) rbt" where
  "t4 = RBT.insert 1 ''a'' (RBT.insert 2 ''b'' (RBT.insert 3 ''c'' RBT.empty))"

value "RBT.lookup t4 2"
value "RBT.lookup t4 9"
value "RBT.impl_of t4"
value "RBT_Impl.is_rbt (RBT.impl_of t4)"
value "RBT_Impl.bheight (RBT.impl_of t4)"

text \<open>插入三次后底层是一棵具体的平衡树（求值可见形状），
@{const RBT_Impl.is_rbt} 检查为 @{term True}。
语义等式一族全是 simp 规则，逐键复述操作的含义：\<close>

lemma "RBT.lookup (RBT.insert 1 ''z'' t4) 1 = Some ''z''"
  by (simp add: t4_def)

lemma "RBT.lookup (RBT.delete 2 t4) 2 = None"
  by (simp add: t4_def)

text \<open>背后是 @{thm RBT.lookup_insert [no_vars]}、
@{thm RBT.lookup_delete [no_vars]}、
@{thm RBT.lookup_empty [no_vars]}——抽象层的查找语义就是偏函数层的
更新/删除/空。批量构造 @{const RBT.bulkload} 接收无序表，
内部先排序再线性建树：\<close>

value "RBT.keys (RBT.bulkload [(3::nat, ''c''), (1, ''a''), (2, ''b'')])"

lemma "RBT.lookup (RBT.bulkload [(3::nat, ''c''), (1, ''a'')]) 1 = Some ''a''"
  by simp

text \<open>@{const RBT.keys} 与 @{const RBT.entries} 返回**按键升序**的
列表（不变量 @{const RBT_Impl.rbt_sorted} 的直接红利，
@{thm RBT.sorted_keys [no_vars]} 与 @{thm RBT.distinct_keys [no_vars]}
是 iff 规则）。这与第 57 章 AList 后端的「原样保留插入序」形成对比，
也是红黑树后端的卖点之一。\<close>

value "RBT.keys t4"
value "RBT.entries t4"

section \<open>59.5 map、map_entry、fold、union、combine\<close>

text \<open>改值类操作：@{const RBT.map_entry} 只改存在键，
@{const RBT.map} 全表改值（键不动，结构不动，线性时间）：\<close>

value "RBT.lookup (RBT.map_entry 1 (%s. s @ ''!'') t4) 1"
value "RBT.entries (RBT.map (%k s. length s) t4)"

text \<open>@{const RBT.fold} 按键序折叠所有键值对；@{const RBT.foldi} 多带
一个继续条件，可提前退出：\<close>

value "RBT.fold (%k v acc. acc + k) t4 0"
value "RBT.foldi (%acc. acc < 3) (%k v acc. acc + k) t4 0"

text \<open>两表操作：@{const RBT.union} 是**右表优先**的并
（@{thm RBT.lookup_union [no_vars]}，与 fmap 的 @{verbatim "m ++⇘f n"}
同向）；@{const RBT.combine} 用给定二元函数合并冲突键的值，
@{const RBT.combine_with_key} 的合并函数还能看键：\<close>

value "RBT.lookup (RBT.union t4 (RBT.insert (2::nat) ''z'' RBT.empty)) 2"
value "RBT.lookup (RBT.union (RBT.insert (2::nat) ''z'' RBT.empty) t4) 2"
value "RBT.lookup (RBT.combine (%v w. v + w)
  (RBT.insert (1::nat) (2::nat) RBT.empty)
  (RBT.insert 1 3 (RBT.insert 2 4 RBT.empty))) 1"

section \<open>59.6 RBT_Set：集合的红黑树实现\<close>

text \<open>@{theory "HOL-Library.RBT_Set"} 走另一条路：不给集合立新类型，
而是给**普通** @{typ "'a set"} 安装两个代码构造子
@{verbatim "code_datatype Set Coset"}——@{const RBT_Set.Set} 把一棵
值域为 @{typ unit} 的红黑树解释为它的键集，@{const RBT_Set.Coset}
解释为其补集。于是 Main 里所有集合运算一夜之间获得对数实现：
属于、并交差、过滤、@{const card}、@{const sum}、甚至
@{const Pow}、@{const Min}/@{const Max}、@{const Inf}/@{const Sup}
都配了 @{verbatim code} 等式。源码开头自带警告：导入本理论后，
其它以列表实现集合的代码等式**不再可用**（两种实现打架，见坑 6）。\<close>

definition s1 :: "nat set" where
  "s1 = RBT_Set.Set (RBT.insert 1 () (RBT.insert 3 () (RBT.insert 2 () RBT.empty)))"

value "2 \<in> s1"
value "4 \<in> s1"
value "card s1"
value "s1 \<union> {4}"
value "sorted_list_of_set s1"

text \<open>注意最后一行：@{const sorted_list_of_set} 的代码等式直接是
@{const RBT.keys}——有序键表本来就在树里，取有序列表是免费的
（对比第 58 章 fset 要真的去排序）。补集表示让「有限集的全集」
也可执行：\<close>

value "(1::nat) \<in> RBT_Set.Coset (RBT.insert 2 () RBT.empty)"
value "(2::nat) \<in> RBT_Set.Coset (RBT.insert 2 () RBT.empty)"

section \<open>59.7 RBT_Mapping：Mapping 的对数后端\<close>

text \<open>最后回到第 57 章的抽象字典。@{theory "HOL-Library.RBT_Mapping"}
用红黑树安装构造子 @{verbatim "Mapping"}（要求键是
@{class linorder}），同一套 @{const Mapping.lookup}/
@{const Mapping.update}/@{const Mapping.delete} 接口一个字不改，
实现从线性表换成平衡树：\<close>

definition m4 :: "(nat, string) mapping" where
  "m4 = Mapping (RBT.insert 1 ''a'' (RBT.insert 2 ''b'' RBT.empty))"

value "Mapping.lookup m4 2"
value "Mapping.lookup (Mapping.update 3 ''c'' m4) 3"
value "Mapping.size m4"

text \<open>红黑树后端独有的红利是有序视图：@{const Mapping.ordered_keys}
与 @{const Mapping.ordered_entries} 的代码等式就是
@{const RBT.keys}/@{const RBT.entries}，输出按键升序且免排序：\<close>

value "Mapping.ordered_keys (Mapping.update 3 ''c'' m4)"
value "Mapping.ordered_entries (Mapping.update 3 ''c'' m4)"

lemma "Mapping.lookup (Mapping.update (1::nat) ''z'' m4) 1 = Some ''z''"
  by (simp add: m4_def)

text \<open>选型对照（与第 57.7 节呼应）：写**数学**用 fmap（等式理论最
丰富）；写**可执行库接口**用 Mapping，小规模乱序键选
AList_Mapping，大规模有序键选 RBT_Mapping。还有一个免费福利：
@{theory "HOL-Library.RBT"} 末尾注册了
@{verbatim "quickcheck_generator"}，quickcheck 能直接生成满足
不变量的随机红黑树。\<close>

section \<open>59.8 坑位清单（实测）\<close>

text \<open>
1. @{theory "HOL-Library.RBT"} 结尾用 @{verbatim "hide_const (open)"}
   隐藏了一批未限定名（lookup/insert/delete/keys/entries/…），
   引用必须写全称 @{verbatim "RBT.lookup"} 等；
   实现层同理写 @{verbatim "RBT_Impl.branch"} 不行，
   构造子是 @{verbatim "RBT_Impl.Branch"}（大写）。
2. 键类型必须是 @{class linorder}：@{typ "('a::linorder, 'b) rbt"}
   的 typedef 就带这个约束，@{class order} 不够（第 57 章
   坑 7 同源）。
3. @{term "\<langle>l, x, r\<rangle>"} 的尖括号是 Tree 的 mixfix 语法
   （源码层写作反斜杠命令 langle 与 rangle），不是普通括号；
   空叶是 @{term "\<langle>\<rangle>"}。
4. @{const RBT.union} 右表优先（@{thm RBT.lookup_union [no_vars]}
   的 @{verbatim "lookup s ++ lookup t"} 与 map_add 同向），
   与第 57 章 @{verbatim "m ++⇘f n"} 一致。
5. 理论里只能有一个 Mapping 后端：@{theory "HOL-Library.RBT_Mapping"}
   与 @{verbatim "HOL-Library.AList_Mapping"} 都用
   @{verbatim code_datatype} 安装构造子 @{verbatim Mapping}，
   同导入会互相覆盖（本教程因此把它们放在 57/59 两个理论里）。
6. 导入 @{theory "HOL-Library.RBT_Set"} 会改变**整个项目**的集合
   代码生成：以列表实现集合的 @{verbatim code} 等式被顶掉
   （源码开头的官方警告）。只要 @{verbatim value}/导出代码用到
   集合运算，先想清楚走哪种实现。
7. @{const RBT_Set.Set} 的值域必须是 @{typ unit}——它把
   @{typ "('a, unit) rbt"} 当集合用；想存键值对请回 RBT/Mapping。
8. @{const RBT.entries}/@{const RBT.keys} 恒有序无重复
   （@{thm RBT.sorted_keys [no_vars]} 是 iff 规则）；
   依赖这个性质写证明直接用现成定理，别重新归纳。
9. 红黑树的 @{verbatim "O(log n)"} 来自不变量而非本库的一条
   「高度 \<le> 2 log n」定理——RBT_Impl 只证不变量保持，
   复杂度界的完整形式化在 HOL-Data_Structures（后续批次）。
10. 证 lookup 层面的性质一律走 @{thm RBT.lookup_insert [no_vars]}
    一族 simp 规则（偏函数代数），**不要** unfold 到
    @{const RBT.impl_of} 再跟 @{const RBT_Impl.balance} 的
    五个模式搏斗——那是库作者已经付过的代价。
\<close>

ML \<open>writeln "==== 59 结束 ===="\<close>

end
