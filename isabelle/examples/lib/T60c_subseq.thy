theory T60c_subseq
  imports "HOL-Library.Subseq_Order"
begin

ML \<open>writeln "==== 60c 开始 ===="\<close>

section \<open>60.7 Subseq_Order：子序列即 ≤\<close>

text \<open>@{theory "HOL-Library.Subseq_Order"} 是前缀序的放松：
@{term "xs \<le> ys"} 读作「@{term xs} 是 @{term ys} 的**子序列**」——
从 @{term ys} 里删掉若干元素（不必连续）能得到 @{term xs}，
但保留的相对顺序不变。它同样注册为 @{class order} 实例，
同样与前缀序/字典序互斥。与前缀的关键差别：中间可以「跳」：\<close>

value "([1, 3] :: nat list) \<le> [1, 2, 3]"
value "([3, 1] :: nat list) \<le> [1, 2, 3]"
value "([1, 3] :: nat list) < [1, 2, 3]"

text \<open>第一行 @{verbatim True}（跳过 2）——这句话在前缀序下是
@{verbatim False}，两种序的分野就在这。第二行 @{verbatim False}：
相对顺序必须保留。计算等式 @{thm le_list_Cons2_iff [no_vars]} 就是
经典的「逐头匹配，不等则丢右头」递归。

长度严格增长：\<close>

lemma subseq_len: "xs < ys \<Longrightarrow> length xs < length ys"
  for xs ys :: "'a list"
  by (rule less_list_length)

lemma "([1, 3] :: nat list) < [1, 2, 3]"
  by eval

text \<open>@{const map}/@{const filter} 与子序列序的配合现成：
@{thm le_list_map [no_vars]}、@{thm le_list_filter [no_vars]}——
过滤必得子序列，映射保持子序列关系。\<close>

ML \<open>writeln "==== 60c 结束 ===="\<close>

end
