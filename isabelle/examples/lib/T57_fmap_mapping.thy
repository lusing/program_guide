theory T57_fmap_mapping
  imports "HOL-Library.Finite_Map" "HOL-Library.AList_Mapping"
begin

section \<open>57.1 两种「有限字典」：fmap 与 Mapping\<close>

text \<open>Main 的 @{typ "'a \<rightharpoonup> 'b"} 是函数空间的子集——一个以
@{const None} 表示「缺键」的偏函数。它的数学性质很好（外延性、
映射复合都是现成的），但有两个工程短板：定义域可能无穷，而且
函数本身对代码生成器是不透明的（无法把一个 @{typ "nat \<rightharpoonup> nat"}
导出成可运行的数据结构）。

@{theory "HOL-Library.Finite_Map"} 给出答案的一半：类型
@{typ "('a, 'b) fmap"} 是「定义域有限的偏函数」组成的**子类型**，
用第 28 章的 typedef + Lifting 流水线包装，携带等式理论与可执行实现。
@{theory "HOL-Library.Mapping"}（搭配
@{theory "HOL-Library.AList_Mapping"} 后端）给出另一半：一个**故意
隐藏表示**的抽象映射类型，后端可以在关联表与红黑树之间替换而不改
客户端代码。本章逐个拆解。本理论走 @{verbatim "IsaTutLib"} 会话。\<close>

ML \<open>writeln "==== 57 开始 ===="\<close>

subsection \<open>57.2 fmap 的定义：从偏函数到有限子类型\<close>

text \<open>库中的定义只有一行 typedef：把所有满足 @{term "finite (dom m)"}
的偏函数 @{term m} 收进新类型 @{typ "('a, 'b) fmap"}，两个方向的
投影分别叫 @{const fmlookup}（取出底层偏函数）与 @{const Abs_fmap}
（内部使用）。于是「查键」就是函数应用：@{term "fmlookup m k"}。

外延性定理 @{thm fmap_ext [no_vars]} 保证两张映射相等当且仅当
逐键查找结果相同。这是后面所有等式推理的总开关。先造三张玩具表：\<close>

definition ages :: "(string, nat) fmap" where
  "ages = fmupd ''Ann'' 23 (fmupd ''Bob'' 19 fmempty)"

value "fmlookup ages ''Ann''"
value "fmlookup ages ''X''"
value "fmlookup (fmempty :: (string, nat) fmap) ''Ann''"

text \<open>@{term fmempty} 是空表（每个键都查 @{const None}）；
@{term "fmupd k v m"} 是插入/覆盖。重复覆盖是幂等的，不同键的
更新可交换——这两条都有现成定理 @{thm fmupd_idem [no_vars]} 和
@{thm fmupd_reorder_neq [no_vars]}：\<close>

lemma fmupd_demo:
  "fmupd ''Ann'' 24 ages = fmupd ''Ann'' 24 (fmupd ''Ann'' 25 ages)"
  by (rule fmap_ext; simp)

lemma "fmlookup (fmupd ''Ann'' 24 ages) ''Ann'' = Some 24"
  by (simp add: ages_def)

text \<open>从关联表批量造表用 @{const fmap_of_list}；同键时**表首优先**
（与 Main 的 @{const map_of} 一致）。代码生成时 fmap 正是以这一个
构造子（@{verbatim "code_datatype fmap_of_list"}）落地的：\<close>

value "fmap_of_list [(''Ann'', 23), (''Bob'', 19), (''Ann'', 99)] :: (string, nat) fmap"
value "fmlookup (fmap_of_list [(''Ann'', 23), (''Ann'', 99)] :: (string, nat) fmap) ''Ann''"

lemma ages_via_list: "ages = fmap_of_list [(''Ann'', 23), (''Bob'', 19)]"
  unfolding ages_def by transfer simp

subsection \<open>57.3 定义域与值域：fset 的第一次出场\<close>

text \<open>注意类型：@{const fmdom} 返回的是 @{typ "'a fset"}（第 58 章的
有限集类型），@{const "fmdom'"} 才返回普通 @{typ "'a set"}；
@{const fmran} 的值域也是 fset。判属于用 @{term "x |\<in>| X"}：\<close>

value "fmdom ages"
value "fmdom' ages"
value "fmran ages"
value "''Ann'' |\<in>| fmdom ages"

text \<open>「在定义域里」与「查得到」是同一件事的两种写法，
@{thm fmlookup_dom_iff [no_vars]} 两边互推；空表定义域为空：\<close>

lemma "''X'' |\<notin>| fmdom ages"
  by (simp add: ages_def)

lemma "fmdom (fmempty :: (string, nat) fmap) = {||}"
  by simp

subsection \<open>57.4 并、复合、删除、限制：fmap 的批量代数\<close>

text \<open>@{term "m ++\<^sub>f n"}（@{const fmadd}）是逐键并，**右表优先**
（与 Main 的 @{const "map_add"} 同向：右边覆盖左边同键的值）；
空表是单位元，运算满足结合律（@{thm fmadd_assoc [no_vars]}）。
下面三行依次看到：新键直接并入、右表覆盖 @{term ages} 里的 Ann、
右表 @{term ages} 反过来覆盖左边的 99：\<close>

value "fmlookup (ages ++\<^sub>f fmupd ''Cy'' 30 fmempty) ''Cy''"
value "fmlookup (ages ++\<^sub>f fmupd ''Ann'' 99 fmempty) ''Ann''"
value "fmlookup (fmupd ''Ann'' 99 fmempty ++\<^sub>f ages) ''Ann''"

lemma fmadd_unit: "ages ++\<^sub>f fmempty = ages"
  by (rule fmadd_empty)

text \<open>@{term "g \<circ>\<^sub>f f"}（@{const fmcomp}）是 Kleisli 复合：先查
@{term f}，命中再拿结果去查 @{term g}，任一键在 @{term f} 处缺失
则整体缺失。用两张「父子年龄」表演示：\<close>

definition moms :: "(string, string) fmap" where
  "moms = fmap_of_list [(''Amy'', ''Ann''), (''Leo'', ''Ann'')]"

value "fmlookup (ages \<circ>\<^sub>f moms) ''Amy''"
value "fmlookup (ages \<circ>\<^sub>f moms) ''Leo''"
value "fmlookup (ages \<circ>\<^sub>f moms) ''Ann''"

text \<open>删除一族键用 @{const fmdrop_fset}（fset 版）/@{const fmdrop}
（单键），保留一族键用 @{const fmrestrict_fset}；@{const fmfilter}
**按键**做筛选（谓词类型是 @{typ "'a \<Rightarrow> bool"}，想按值筛请先用
@{const fmpred} 表达条件）。删一个不存在的键什么都不发生
（@{thm fmdrop_idle [no_vars]}）：\<close>

value "fmlookup (fmdrop ''Ann'' ages) ''Ann''"
value "fmrestrict_fset {|''Ann''|} ages"
value "fmfilter (\<lambda>k. k = ''Bob'') ages"

lemma fmdrop_missing: "fmdrop ''X'' ages = ages"
  by (simp add: ages_def fmdrop_idle)

subsection \<open>57.5 像、枚举与序：让 fmap 可计算地遍历\<close>

text \<open>@{const fmimage} 取一批键对应的值（成 fset）；@{const fset_of_fmap}
把整张表摊成键值对的 fset。两者在代码层都 unfold 成「在整个类型上
收集」的普通集合，因此 @{verbatim value} 只对 @{class enum}（有限可
枚举）类型工作——下面用 @{typ bool} 做可求值演示；无穷类型的结论
直接写成引理由化简器算：\<close>

value "fmimage (fmap_of_list [(True, 1::nat), (False, 2)]) {|True|}"
value "fset_of_fmap (fmap_of_list [(True, False), (False, True)])"

lemma "fmimage ages {|''Ann''|} = {|23|}"
  by (auto simp add: fset_eq_iff ages_def fmlookup_image_iff)

lemma "fset_of_fmap ages = {|(''Ann'', 23), (''Bob'', 19)|}"
  by (auto simp add: fset_eq_iff ages_def)

text \<open>当键类型带 @{class linorder} 时，@{const sorted_list_of_fmap}
给出按键排序、无重复的关联表——这正是 fmap 与第 59 章红黑树后端
对接的接口。@{const size} 统计键的个数：\<close>

value "sorted_list_of_fmap (fmap_of_list [(3::nat, ''c''), (1, ''a''), (2, ''b'')])"

text \<open>@{const size} 在代码层等于「键值对 fset 的基数」
（@{thm size_fmap_overloaded_simps [no_vars]}），无穷类型下同样不能
@{verbatim value}；可求值的计数走排序表长度：\<close>

value "length (sorted_list_of_fmap (fmap_of_list [(1::nat, ''a''), (2, ''b''), (1, ''z'')]))"

text \<open>在 @{class enum} 类型上 @{const size} 可以直接求值（注意同键覆盖
后仍只算一个）：\<close>

value "size (fmap_of_list [(True, False), (False, True), (True, True)])"

text \<open>@{const fmsubset}（@{term "m \<subseteq>\<^sub>f n"}）是点态包含：键集包含且
共有键上的值一致；@{const fmpred} 是「所有键值对都满足」：\<close>

value "fmap_of_list [(''Ann'', 23::nat)] \<subseteq>\<^sub>f ages"
value "fmpred (\<lambda>b n. n > 0) (fmap_of_list [(True, 1::nat)])"

lemma "fmpred (\<lambda>_ n. n > 18) ages"
  by (simp add: ages_def fmpred_iff)

subsection \<open>57.6 Mapping：表示无关的抽象字典\<close>

text \<open>@{typ "('a, 'b) mapping"} 的构造方式与 fmap 几乎平行（同样
typedef 自有限偏函数），但设计意图不同：它的构造子在核心理论里
**不导出**，代码等式由后端理论单独安装。导入
@{theory "HOL-Library.AList_Mapping"} 后，构造子
@{const Mapping}（注意大写，与类型同名）以关联表为表示，
@{term "Mapping xs"} 直接用 Main 的 @{const map_of} 解释，
查找因此退化成列表上的线性查找：\<close>

value "Mapping.lookup (Mapping.empty :: (nat, string) mapping) 1"
value "Mapping.lookup (Mapping.update (1::nat) ''a'' Mapping.empty) 1"
value "Mapping.lookup (Mapping [(1::nat, ''a''), (2, ''b'')]) 2"

text \<open>日常 API 与 fmap 对应，但结果回到普通集合/选项：
@{const Mapping.keys}、@{const Mapping.entries}、@{const Mapping.delete}、
@{const Mapping.is_empty}、@{const Mapping.size}：\<close>

value "Mapping.keys (Mapping [(1::nat, ''a''), (2, ''b''), (1, ''z'')])"
value "Mapping.entries (Mapping [(1::nat, ''a''), (2, ''b''), (1, ''z'')])"
value "Mapping.is_empty Mapping.empty"
value "Mapping.size (Mapping [(1::nat, ''a''), (2, ''b''), (1, ''z'')])"

text \<open>三个批量构造子值得记住：@{const Mapping.tabulate} 按键表与一个
函数造表；@{const Mapping.bulkload} 用一张「第 n 个元素值为 n」的
列表造 @{typ "(nat, 'b) mapping"}（数组即字典）；
@{const Mapping.map_values} 改值不改键：\<close>

value "Mapping.lookup (Mapping.tabulate [1::nat, 2, 3] (\<lambda>n. n * n)) 3"
value "Mapping.lookup (Mapping.bulkload [''a'', ''b'', ''c'']) 2"
value "Mapping.lookup (Mapping.map_values (\<lambda>_ v. v @ ''!'')
  (Mapping [(1::nat, ''a'')])) 1"

text \<open>@{const Mapping.map_entry} 只在键存在时改值（不存在不插入）；
@{const Mapping.combine} 用一个二元函数合并两张表。查表带默认值用
@{const Mapping.lookup_default}：\<close>

value "Mapping.lookup (Mapping.map_entry (1::nat) (apsnd (\<lambda>_::bool. True))
  (Mapping [(1, (''a'', False))])) 1"
value "Mapping.lookup (Mapping.combine (\<lambda>v w. v + w)
  (Mapping [(1::nat, 2::nat)]) (Mapping [(1, 3), (2, 4)])) 1"
value "Mapping.lookup_default (0::nat) (Mapping [(1::nat, 2::nat)]) 9"

subsection \<open>57.7 同一个抽象，两种后端：为什么这样分层\<close>

text \<open>关键事实：本章所有 @{verbatim value} 都只依赖
@{verbatim "Mapping.lookup / Mapping.update"} 一族**抽象**操作；把导入从
AList_Mapping 换成
@{verbatim "HOL-Library.RBT_Mapping"}（键需 @{class linorder}），
同一批命题一个字不用改，运行时表示从无序列表变成平衡红黑树，
查找由线性变对数。第 59 章会实际用红黑树后端跑一遍。

选择建议：形式化推理（定理、传递、商类型上的构造）用 fmap——它的
等式理论（lookup 为态射）更丰富，还能直接出现在项里被
@{method transfer} 搬到普通 map；组织可执行库的接口用 Mapping——
表示被刻意藏起，后端可换。\<close>

subsection \<open>57.8 坑位清单（实测）\<close>

text \<open>
1. Finite_Map / AList_Mapping 都属于 @{verbatim "HOL-Library"} 会话，
   必须以 imports 形式引入（如 @{verbatim "HOL-Library.Finite_Map"}），
   裸名在 Main 会话未定义。
2. @{const fmdom} 与 @{const fmran} 返回 fset，属于普通 set 的是
   @{const "fmdom'"}（带撇）；属于关系时还有 @{const "fmran'"}。
3. fmap 没有字面量语法，构造一律走 @{const fmempty}/@{const fmupd}/
   @{const fmap_of_list}；不要凭印象写 @{verbatim "{| k \<mapsto> v |}"}。
4. fset 字面量是 @{verbatim "{| |}"} 双竖线（@{term "{||}"} 为空），
   别和多重集的 @{verbatim "{# #}"}、普通集合的 @{verbatim "{ }"} 混。
5. @{term "m ++\<^sub>f n"} 是**右表优先**（与 @{const map_add} 同向），
   想让新值胜出就把更新写在右边。
6. 同一理论里不要同时导入 AList_Mapping 和 RBT_Mapping：两边都用
   @{verbatim code_datatype} 安装构造子 @{const Mapping}，代码等式
   会互相覆盖；一个理论选一个后端。
7. @{const sorted_list_of_fmap} 与 RBT 后端都要求键类型是
   @{class linorder}，只有 @{class order} 不够。
8. @{const fmap_of_list} 同键表首优先；@{term "fmap_of_list xs = fmempty"}
   当且仅当去重后为空，证明用 @{thm fmap_of_list_simps [no_vars]}。
9. Mapping 的构造子（大写 @{const Mapping}）只在后端理论里可用；
   只导入 @{theory "HOL-Library.Mapping"} 时 @{verbatim value} 会报
   没有代码等式。
10. @{const size} 在 fmap 上数的是**不同键**的个数（fmap 每键至多
    一个值，不存在「重数」概念，需要重数请回第 45 章 multiset）；
    而且 @{const size}、@{const fset_of_fmap}、@{const fmimage}、
    @{const fmpred} 的代码等式 unfold 成在整个类型上收集的普通集合，
    @{verbatim value} 只接受 @{class enum}（有限可枚举）类型，无穷
    类型上要结果就写引理由化简器算，或改用 @{const sorted_list_of_fmap}。
\<close>

ML \<open>writeln "==== 57 结束 ===="\<close>

end
