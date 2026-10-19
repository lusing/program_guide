theory T60d_lenlex
  imports "HOL-Library.List_Lenlexorder"
begin

ML \<open>writeln "==== 60d 开始 ===="\<close>

section \<open>60.7bis List_Lenlexorder：长度优先的字典序\<close>

text \<open>@{theory "HOL-Library.List_Lenlexorder"} 是字典序的变体：
**先比长度，长度相同再逐元素比**（底层是 Main 的 @{const lenlex}
关系，@{term "xs < ys \<longleftrightarrow> (xs, ys) \<in> lenlex {(u, v). u < v}"}）。
它与 @{verbatim "HOL-Library.List_Lexorder"} 一样占据列表的序类
实例位，两者只能二选一。行为对照立刻可见——60.3 里判负的
例子在这里翻案：\<close>

lemma "([5] :: nat list) < [1, 2]"
  by (simp add: Cons_less_Cons)

lemma "([1, 2] :: nat list) < [1, 3]"
  by (simp add: Cons_less_Cons)

lemma "\<not> ([2, 1] :: nat list) < [1, 3]"
  by (simp add: Cons_less_Cons)

text \<open>第一行：长度 1 < 2，首元素 5 > 1 也无妨——这正是 60.3
锚点例子的反结论。第三行：同长度退回逐元素，2 > 1 判负。

为什么要有这个变体？为了**良序**。普通字典序下 nat 列表有无穷
降链 @{verbatim "[1] > [0,1] > [0,0,1] > …"}（每一步在左侧补 0），
不是良基关系；长度优先后，降链的长度必须严格下降，触底即止。
底层依赖 Main 的 @{thm wf_lenlex [no_vars]}（良基关系经
@{const lenlex} 提升仍良基），本理论顺势给出
@{verbatim "instance list :: (wellorder) wellorder"}——元素良序
则列表（长度优先字典序）良序。需要「字符串归纳」时（如形式语言、
字符串重写里的归纳证明），这是直接可用的武器；前缀序/子序列序
都只是偏序，给不了这个。\<close>

ML \<open>writeln "==== 60d 结束 ===="\<close>

end
