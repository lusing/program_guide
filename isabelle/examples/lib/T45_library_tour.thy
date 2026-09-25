theory T45_library_tour
  imports "HOL-Library.Multiset" "HOL-Library.Sublist" "HOL-Library.AList"
          "HOL-Library.While_Combinator"
begin

section \<open>45.1 Main 之外：HOL-Library 导览\<close>

text \<open>第 40 章逛了 @{verbatim "Main"}；库索引的下一站是
@{verbatim "HOL-Library"}——几十个"值得进标准库但不必进 Main"的理论。
本章按**使用频率**挑四件：多重集（@{verbatim "Multiset"}）、
子序列（@{verbatim "Sublist"}）、关联表（@{verbatim "AList"}）、
while 组合子（@{verbatim "While_Combinator"}，第 35 章的手搓版
在这里有官方正品）。本理论走 @{verbatim "IsaTutLib"} 会话。\<close>

ML \<open>writeln "==== 45 开始 ===="\<close>

subsection \<open>45.2 Multiset：多重集\<close>

text \<open>@{verbatim "'a multiset"} = 带重数的袋子。字面量
@{verbatim "{# 1, 2, 2 #}"}，并是 @{verbatim "+"}（重数相加），
@{verbatim "count"} 数元素，@{verbatim "set_mset"} 摊平：\<close>

value "count ({#1, 2, 2#} + {#2, 3#} :: nat multiset) 2"
value "set_mset ({#1, 2, 2#} + {#3#} :: nat multiset)"

lemma count_add_mset: "count (add_mset x A) y = (if x = y then Suc (count A y) else count A y)"
  by simp

text \<open>@{verbatim "add_mset"} 加一个元素（区别于整包并）。
多重集是第 52 章终止性度量（multiset 序）的载体。\<close>

subsection \<open>45.3 Sublist：子序列与前后缀\<close>

value "prefix [1, 2] [1, 2, 3 :: nat]"
value "suffix [2, 3] [1, 2, 3 :: nat]"
value "sublist [1, 3] [1, 2, 3 :: nat]"

lemma prefix_le: "prefix xs ys \<Longrightarrow> length xs \<le> length ys"
  by (auto simp: prefix_def)

subsection \<open>45.4 AList：关联表即对偶表\<close>

text \<open>@{verbatim "('k <times> 'v) list"} 上"先到先得"的查找语义——
查找用 Main 的 @{verbatim "map_of"}，维护用 AList 的
@{verbatim "AList.update"}（**qualified**，带命名空间前缀）。
实测**没有** @{verbatim "AList.lookup"} 这个函数：\<close>

value "map_of [(1::nat, ''a''), (2::nat, ''b'')] (2::nat)"
value "map_of (AList.update (2::nat) ''B''
  [(1::nat, ''a''), (2::nat, ''b'')]) (2::nat)"

lemma map_of_update: "map_of (AList.update k v al) k = Some v"
  by (induct al) auto

subsection \<open>45.5 While_Combinator：官方 while\<close>

text \<open>第 35 章手搓的 @{verbatim "mywhile"} 在这里有带终止性引理的
正版。Collatz 从 6 出发实测：\<close>

value "while_option (\<lambda>n. n \<noteq> (1::nat))
  (\<lambda>n. if even (n::nat) then n div 2 else 3 * n + 1) 6"

text \<open>配套定理 @{verbatim "while_option_stop"}（终态必不满足条件）
与 @{verbatim "while_option_induct"}（对执行步数归纳）。
终止性的一般判据：@{verbatim "wf"} 关系上每步下降——
@{verbatim "option_while"}? 用法见第 35 章选型表。\<close>

lemma while_stop: "while_option b c s = Some t \<Longrightarrow> \<not> b t"
  by (auto simp: while_option_stop)

subsection \<open>45.6 其余货架（文档节）\<close>

text \<open>没进本章但常用的：@{verbatim "Code_Target_Numeral"}
（按目标语言编译数字）、@{verbatim "Code_Lazy"}（惰性化任意 datatype，
第 36 章流的可执行化）、@{verbatim "DAList"}（Distinct-key 关联表）、
@{verbatim "Permutations"}（排列与组合计数引理）、
@{verbatim "Disjoint_Sets"}（不相交集族）、@{verbatim "List_Lexorder"}
（列表的字典序 instance）、@{verbatim "Tree"} / @{verbatim "Tree23"}
（搜索树家族）。会话依赖写法见本章头部 imports——四行 import
就是四件货架的取货单。\<close>

subsection \<open>45.7 坑位清单（实测）\<close>

text \<open>1. Library 理论**必须**从 HOL-Library 会话引入：
   imports 一行写 HOL-Library.Multiset——写
   @{verbatim "Multiset"} 裸名在 Main 会话报 undefined。
2. @{verbatim "{# ... #}"} 字面量元素要带类型（一次成型给
   @{verbatim "nat multiset"}），不然数字字面量老坑复发。
3. @{verbatim "AList.lookup"} 第一个参数是相等函数
   （@{verbatim "op ="}），不是隐式的——列表元素类型没有
   @{verbatim "equal"} instance 时自由换。
4. @{verbatim "sublist"} 的谓词版/布尔版重载：三个参数与两个参数
   的 @{verbatim "sublist"} 不是同一常量，help 不看清楚容易混。\<close>

thm count_add_mset map_of_update while_stop

ML \<open>writeln "==== 45 结束 ===="\<close>

end
