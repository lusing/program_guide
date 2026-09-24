theory T03_terms_types
  imports Main
begin

section \<open>3.1 项与类型：所有证明的材料\<close>

text \<open>HOL 里一切都是项：数据是项，公式也是 bool 类型的项。
本章过一遍常用类型与书写细节，全部用 @{verbatim "value"} 实测。\<close>

ML \<open>writeln "==== 03 开始 ===="\<close>

subsection \<open>3.2 基础类型与字面量\<close>

value "(1::nat) + 1"         \<comment> \<open>自然数：没有负数\<close>
value "(-1::int) + 1"        \<comment> \<open>整数：有负数\<close>

text \<open>注意：实数类型 \<open>real\<close> 不在 \<open>Main\<close> 里，
要用实数得 @{verbatim "imports Complex_Main"}——很多教程直接写
\<open>imports Main\<close> 然后奇怪类型找不到，这是第一堵墙。\<close>
value "True \<and> \<not> False"
value "if 2 < (3::nat) then (1::nat) else 0"

text \<open>同一种写法 @{verbatim "1 + 1"} 在 nat 与 int 上都成立，
因为加法是类型类 @{verbatim "plus"} 提供的多态运算——
类型类在第 20 章展开。但多态会产生歧义，所以教程里坚持写类型标注。\<close>

subsection \<open>3.3 类型推断与歧义错误的样子\<close>

text \<open>下面这条如果去掉标注，Isabelle 无法决定 @{verbatim "+"} 的类型，
报错是 @{verbatim "Wellsortedness error"}：它不是语法错误，
而是"字面量不知道放哪个类型"。经验法则：算术表达式永远写标注。\<close>

value "(2::nat) ^ 10"
value "(2::int) ^ 10"

subsection \<open>3.4 函数、元组与列表\<close>

value "(\<lambda>x. x + 1) (3::nat)"
value "fst (1::nat, (2::int))"
value "snd (1::nat, (2::int))"
value "((1::nat, 2::int) = (1::nat, 2::int))"
value "length [10::nat, 20, 30]"
value "hd [10::nat, 20]"
value "tl [10::nat, 20]"
value "nth [10::nat, 20, 30] 1"

text \<open>列表是同构的：所有元素同一类型；元组可以异构。
函数应用是空格：@{verbatim "f x y"}，优先级最高的运算。\<close>

subsection \<open>3.5 公式即 bool 项：量词与连接词\<close>

value "((\<lambda>x::nat. x \<ge> 0) (5::nat))"
value "((\<lambda>x::nat. x > 0 \<and> x < 2) (1::nat))"
value "(\<lambda>n::nat. n = 0) 0"

text \<open>量化命题（\<open>\<forall>x::nat. x \<ge> 0\<close>）不能交给
@{verbatim "value"}：代码生成器只会"算"，枚举不了无穷多个
自然数。量化公式是 \<open>blast\<close> 的领地：\<close>

lemma "(\<forall>x. P x) \<longrightarrow> (\<exists>x. P x)"
  by blast

text \<open>最后一行展示了"谓词就是函数"：lambda 应用于 0 得到
@{verbatim "0 = 0"}，由求值器化简为 True。\<close>

subsection \<open>3.6 用 ML 观察项与类型\<close>

ML \<open>
  writeln (@{make_string} @{term "map"});
  writeln (@{make_string} @{typ "'a list \<Rightarrow> 'a list"});
  writeln (@{make_string} @{term "length"})
\<close>

text \<open>@{verbatim "@{term map}"} 在 ML 里展开为多态常量项，
打印出来的 @{verbatim "?a"} 是类型变量。@{verbatim "@{typ …}"}
展开为类型。另一个细节：@{verbatim "length"} 打印出来是
@{verbatim "Nat.size_class.size"}——列表的 length 只是 size
的缩写记号，不是独立常量。这三兄弟在第 23 章的
antiquotation 清单里还会再见。\<close>

ML \<open>writeln "==== 03 结束 ===="\<close>

end
