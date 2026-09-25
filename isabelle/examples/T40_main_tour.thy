theory T40_main_tour
  imports Main
begin

section \<open>40.1 Main 是个军火库：导览图\<close>

text \<open>"What's in Main"（main.pdf）是官方的库目录：Main 理论汇拢了
HOL 日常计算的全部基础设施。本章按**军种**导览一遍——每样都过
@{verbatim "value"} 实测，别背目录，记住"哪类问题去哪个货架"：

  - 算术：@{verbatim "nat"}/@{verbatim "int"}（第 11 章）、
    @{verbatim "Groups"}（+、-、乘、幂）、@{verbatim "Rings"}；
  - 大算子：@{verbatim "<Sum>"}（set/list 上的求和）、@{verbatim "<Prod>"}；
  - 列表：第 10 章全套 + @{verbatim "upt"}、@{verbatim "sorted"}；
  - 集合：第 14 章 + @{verbatim "card"}、@{verbatim "finite"}、
    @{verbatim "Max"}/@{verbatim "Min"}；
  - 映射：@{verbatim "'a <rightharpoonup> 'b"}（部分映射，函数的语法糖
    语法层）；
  - 字符串：@{verbatim "char"} 的 nibble 内幕、@{verbatim "string"}
    = @{verbatim "char list"}；
  - 描述算子：@{verbatim "THE"}、@{verbatim "Eps"}。\<close>

ML \<open>writeln "==== 40 开始 ===="\<close>

subsection \<open>40.2 大算子：\<Sum> 与 \<Prod>\<close>

value "\<Sum>x\<in>{1..(10::nat)}. x * x"
value "sum_list [1, 2, 3, 4 :: nat]"
value "prod_list [1, 2, 3, 4 :: nat]"
value "(\<Sum>x\<leftarrow>[(1::nat), 2, 3]. x)"

text \<open>@{verbatim "{1..10}"} 是区间集合语法（@{verbatim "atLeastAtMost"}）。
集合版 @{verbatim "<Sum>x\<in>A. f x"} 要求**交换幺半群**载体；
列表版 @{verbatim "sum_list"} 只要幺半群。集合版的化简靠
@{verbatim "sum.insert"} 一族，列表版靠 @{verbatim "sum_list.Cons"}。\<close>

lemma sum_distr_range: "(\<Sum>x\<in>{1..n::nat}. 2 * x) = 2 * (\<Sum>x\<in>{1..n}. x)"
  by (simp add: sum_distrib_left)

subsection \<open>40.3 有限集：card / finite / Max\<close>

value "card {i \<in> {1..(10::nat)}. i mod 2 = 0}"
value "Max {3, 1, 4, 1, 5 :: nat}"
value "Min {3, 1, 4, 1, 5 :: nat}"

lemma card_even_4: "card {1::nat, 3} = 2"
  by simp

subsection \<open>40.4 映射：partial 函数的语法糖\<close>

text \<open>@{verbatim "'a <rightharpoonup> 'b"} 就是 @{verbatim "'a <Rightarrow> 'b option"}
的别名。库送来 @{verbatim "dom"}（定义域）、@{verbatim "ran"}、
@{verbatim "map_add"}（右偏合并）、@{verbatim "restrict_map"}：\<close>

definition ages :: "string \<rightharpoonup> nat" where
  "ages = [''ana'' \<mapsto> 3, ''bob'' \<mapsto> 5]"

value "the (ages ''ana'')"

text \<open>@{verbatim "''ana''"} 是 @{verbatim "char list"} 字面量
（第 40.6 节内幕；@{verbatim "STR"} 前缀是 @{verbatim "String.literal"}——
两种字符串类型实测混用直接类型撞车）。@{verbatim "[k <mapsto> v]"}
是单点映射语法。合并 @{verbatim "map_add"} **右侧优先**（右边覆盖
左边）；@{verbatim "dom ages"} 求值要键类型有 @{verbatim "enum"}
实例——@{verbatim "char list"} 没有（实测 Wellsortedness），
键可枚举才好 value。\<close>

lemma map_add_find: "m2 k = Some v \<Longrightarrow> map_add m1 m2 k = Some v"
  by (simp add: map_add_def)

subsection \<open>40.5 描述算子：THE 与 Eps\<close>

text \<open>@{verbatim "THE x. P x"} 是唯一描述（"那个唯一的 x"），
@{verbatim "Eps"}（@{verbatim "SOME"}）是选择算子（"随便挑一个，
挑哪个不保证"）。工程上 @{verbatim "THE"} 配合唯一性证明使用：\<close>

definition smallest_pos :: "nat set \<Rightarrow> nat" where
  "smallest_pos A = (THE x. x \<in> A \<and> (\<forall>y \<in> A. x \<le> y))"

lemma the_min_singleton: "smallest_pos {(3::nat), 1, 2} = 1"
  unfolding smallest_pos_def
proof (rule the_equality, goal_cases)
  case 1
  then show ?case by auto
next
  case (2 y)
  then show ?case by auto
qed

text \<open>@{verbatim "the_equality"}：证 @{verbatim "THE"} 的两步——
存在 + 唯一。忘了唯一性，@{verbatim "THE"} 项毫无计算意义。\<close>

subsection \<open>40.6 字符串与 nibble 内幕\<close>

text \<open>@{verbatim "string = char list"}，而 @{verbatim "char"} 是
**8 个半字节（nibble）的枚举**——所以 @{verbatim "''A''"} 能被
@{verbatim "value"} 算出来：\<close>

value "(CHR 0x41, length ''hello'')"
value "''AB'' = [CHR 0x41, CHR 0x42]"
value "String.implode ''ok'' = STR ''ok''"

text \<open>@{verbatim "CHR 0x41"} 的十六进制语法直连 nibble 结构。
@{verbatim "String.implode/explode"} 在 @{verbatim "String.literal"}
（Literal 字符串，code 生成友好）与 @{verbatim "string"} 之间摆渡。\<close>

subsection \<open>40.7 坑位清单（实测）\<close>

text \<open>1. @{verbatim "<Sum>x\<in>A. f x"} 的载体必须推出交换幺半群：
   自定义类型先装 @{verbatim "comm_monoid_add"}（第 25 章）。
2. @{verbatim "Max"} 空集是 @{verbatim "undefined"}——用之前
   @{verbatim "A <noteq> {}"} 要在手上。
3. @{verbatim "card"} 的化简只对**显式有限**集合快；谓词集合先
   @{verbatim "auto"} 转 @{verbatim "card image"} 形态。
4. 映射合并 @{verbatim "map_add"} 右优先，记反了查找行为悄悄错。
5. @{verbatim "THE"} 无唯一性证明时不可计算——@{verbatim "value"}
   直接报错或给出 @{verbatim "undefined"}。
6. @{verbatim "''...''"} 是 @{verbatim "char list"}；code 生成到
   目标语言时记得它不是原生长串，导出侧另有 @{verbatim "String.literal"}。
7. @{verbatim "{1..n}"} 两侧闭区间；步进版 @{verbatim "{1..<n}"} 才是
   左闭右开（差一个元素的经典笔误）。
8. @{verbatim "sum_list"}/@{verbatim "prod_list"} 位置：列表章不是
   集合章，别和 @{verbatim "<Sum>"} 混写。\<close>

thm sum_distr_range card_even_4 the_min_singleton

ML \<open>writeln "==== 40 结束 ===="\<close>

end
