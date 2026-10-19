theory T60b_prefix
  imports "HOL-Library.Prefix_Order"
begin

ML \<open>writeln "==== 60b 开始 ===="\<close>

section \<open>60.6 Prefix_Order：前缀即 ≤\<close>

text \<open>@{theory "HOL-Library.Prefix_Order"} 把列表的 @{const prefix}
关系注册成 @{class order} 类实例：@{term "xs \<le> ys"} 从此读作
「@{term xs} 是 @{term ys} 的前缀」，@{term "xs < ys"} 是严格前缀
（@{const strict_prefix}）。这是一次**故意的主从选择**：列表的序
从此固定为前缀序，字典序（60.3）与子序列序（60.7）就不能再与
它同堂（类实例唯一，见坑位清单）。

前缀序是偏序而非线序——@{term "[1,2]"} 与 @{term "[1,3]"} 互不可比：\<close>

lemma "([1, 2] :: nat list) \<le> [1, 2, 3]"
  by simp

lemma "\<not> ([1, 2] :: nat list) \<le> [1, 3] \<and> \<not> ([1, 3] :: nat list) \<le> [1, 2]"
  by simp

lemma "([1, 2] :: nat list) < [1, 2, 3]"
  by simp

value "([1, 2] :: nat list) < [1, 2, 3]"
value "([2, 1] :: nat list) < [1, 2, 3]"

text \<open>空表是普遍前缀（@{thm Nil_prefix [no_vars]}，行为类似底元素），
长度单调（前缀不长于全串）：\<close>

lemma "[] \<le> (xs :: 'a list)"
  by simp

lemma prefix_len: "xs \<le> ys \<Longrightarrow> length xs \<le> length ys"
  for xs ys :: "'a list"
  by (rule prefix_length_le)

ML \<open>writeln "==== 60b 结束 ===="\<close>

end
