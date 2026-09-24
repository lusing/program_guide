theory T10_lists
  imports Main
begin

section \<open>10.1 list：教程里最常用的数据结构\<close>

text \<open>列表函数库里有一百多个函数，本章只挑高频的：
@{verbatim "map"} @{verbatim "filter"} @{verbatim "fold"} @{verbatim "rev"}
@{verbatim "concat"} @{verbatim "zip"} @{verbatim "nth"} @{verbatim "upt"}。
每条都先求值看行为，再证一条性质。\<close>

ML \<open>writeln "==== 10 开始 ===="\<close>

subsection \<open>10.2 高频函数实测\<close>

value "map (\<lambda>n::nat. n + 1) [1, 2, 3]"
value "filter (\<lambda>n::nat. n > 1) [1, 2, 3]"
value "foldr (+) [1::nat, 2, 3] 0"
value "foldl (+) 0 [1::nat, 2, 3]"
value "rev [1::nat, 2, 3]"
value "concat [[1::nat, 2], [3]]"
value "zip [1::nat, 2] [10::int, 20]"
value "nth [1::nat, 2, 3] 1"
value "upt (0::nat) 4"

subsection \<open>10.3 map 保持拼接\<close>

lemma map_append: "map f (xs @ ys) = map f xs @ map f ys"
  by (induction xs) simp_all

lemma map_compose: "map f (map g xs) = map (\<lambda>x. f (g x)) xs"
  by (induction xs) simp_all

subsection \<open>10.4 rev 与 map 的交换律\<close>

lemma rev_append: "rev (xs @ ys) = rev ys @ rev xs"
  by (induction xs) simp_all

lemma rev_map: "rev (map f xs) = map f (rev xs)"
  by (induction xs) simp_all

subsection \<open>10.5 filter 与 length\<close>

lemma filter_append: "filter P (xs @ ys) = filter P xs @ filter P ys"
  by (induction xs) simp_all

lemma length_filter_le: "length (filter P xs) \<le> length xs"
  by (induction xs) (auto intro: le_trans le_SucI)

subsection \<open>10.6 折叠：fold 与 sum_list\<close>

lemma sum_list_append: "sum_list (xs @ ys) = sum_list xs + sum_list ys"
  by (induction xs) (simp_all add: add.assoc)

value "sum_list [1::nat, 2, 3]"

subsection \<open>10.7 折叠与反转的对偶（Fold duality）\<close>

text \<open>foldl 与 foldr 在结合律下相等，是列表编程的经典结论：\<close>

lemma foldl_foldr: "foldl (+) (a::nat) xs = foldr (+) (rev xs) a"
  by (induction xs arbitrary: a) (simp_all add: add.commute add.left_commute add.assoc)

value "foldl (+) (0::nat) [1, 2, 3]"

subsection \<open>10.8 第 n 个元素的安全包装\<close>

fun nth_opt :: "'a list \<Rightarrow> nat \<Rightarrow> 'a option" where
  "nth_opt [] n = None"
| "nth_opt (x # xs) 0 = Some x"
| "nth_opt (x # xs) (Suc n) = nth_opt xs n"

value "nth_opt [10::nat, 20] 1"
value "nth_opt [10::nat, 20] 5"

lemma nth_opt_len: "nth_opt xs n = Some x \<Longrightarrow> n < length xs"
  apply (induction xs n rule: nth_opt.induct)
    apply simp_all
  done

ML \<open>writeln "==== 10 结束 ===="\<close>

end
