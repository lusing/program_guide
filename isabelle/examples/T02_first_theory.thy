theory T02_first_theory
  imports Main
begin

section \<open>2.1 一个最小的完整理论\<close>

text \<open>本章从零写一个能构建通过的最小理论：定义函数、叙述命题、
完成证明。文件骨架是 @{verbatim "theory"}…@{verbatim "begin"}…@{verbatim "end"}，
中间夹定义与证明。\<close>

ML \<open>writeln "==== 02 开始 ===="\<close>

subsection \<open>2.2 定义递归函数\<close>

fun app :: "'a list \<Rightarrow> 'a list \<Rightarrow> 'a list" where
  "app [] ys = ys"
| "app (x # xs) ys = x # app xs ys"

text \<open>标准库其实自带拼接运算符 \<open>@\<close>（即 append）。
自定义 \<open>app\<close> 的价值在于看清 \<open>fun\<close> 的机械：
每个方程都变成一条化简规则。下面的 \<open>shu\<close>（反转）
直接用标准 \<open>@\<close>。\<close>

fun shu :: "'a list \<Rightarrow> 'a list" where
  "shu [] = []"
| "shu (x # xs) = shu xs @ [x]"

text \<open>@{verbatim "fun"} 自动生成每条方程对应的化简规则，名字是
@{verbatim "app.simps"} 等。先求值看看行为，再看规则长什么样。\<close>

value "app [1::nat, 2] [3, 4]"
value "shu [1::nat, 2, 3]"

ML \<open>
  writeln (@{make_string} (hd @{thms app.simps}));
  writeln (@{make_string} (hd (tl @{thms app.simps})))
\<close>

subsection \<open>2.3 叙述并证明第一条引理\<close>

lemma app_nil_r [simp]: "app xs [] = xs"
  by (induction xs) auto

text \<open>对标准 \<open>@\<close> 也先补两条常识：右端空表可消去；
拼接满足结合律——这两条标准库里已有同名版本
（append_Nil2、append_assoc），此处自证一遍体验流程。\<close>

text \<open>@{verbatim "by (induction xs) auto"} 是两个方法的组合：
先做归纳，再用自动化收尾。它是第 6 章 induct 与第 8 章 auto 的预告。\<close>

lemma shu_append: "shu (xs @ ys) = shu ys @ shu xs"
  by (induction xs) auto

lemma shu_shu: "shu (shu xs) = xs"
  by (induction xs) (auto simp: shu_append)

text \<open>三个证明都只有一行。关键在 @{verbatim "shu_append"}：
不先证它，@{verbatim "auto"} 在归纳步骤就卡在
@{verbatim "shu (shu xs @ [a])"} 上不动——这正是初学者最常撞的墙。
第 6 章会逐帧回放这里的归纳。\<close>

subsection \<open>2.4 把定义和定理再观察一遍\<close>

ML \<open>
  writeln (@{make_string} @{thm shu_append});
  writeln (@{make_string} @{thm shu_shu})
\<close>

value "shu ([1::nat, 2] @ [3])"
value "shu (shu [1::int, 2, 3])"

subsection \<open>2.5 开发循环：写一点、证一点、构建一点\<close>

text \<open>推荐的工作循环是：
(1) 在 jEdit 里写定义，看面板是否全蓝（无悬空错误）；
(2) 写 lemma 后先用 @{verbatim "oops"} 占位跑通结构；
(3) 逐个补证明，@{verbatim "isabelle build"} 全量把关。
@{verbatim "oops"} 表示"放弃这个证明"，只在开发期使用，构建通过的
最终示例里不允许出现。\<close>

ML \<open>writeln "==== 02 结束 ===="\<close>

end
