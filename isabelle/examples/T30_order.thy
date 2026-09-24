theory T30_order
  imports Main
begin

section \<open>30.1 类层次概览\<close>

text \<open>第 25 章讲过 @{verbatim "class"}。HOL 里 @{verbatim "Orderings"} 与
@{verbatim "Lattices"} 定义了**极大的一族序/格类**，共同构成一棵继承树：

\begin{itemize}
\item @{verbatim "preorder"} —— 自反 + 传递（@{verbatim "\<le>"}）
\item @{verbatim "partial_order"} —— preorder + 反对称
\item @{verbatim "linorder"} —— partial\_order + 完全（@{verbatim "a \<le> b \<or> b \<le> a"}）
\item @{verbatim "semilattice_sup"} / @{verbatim "semilattice_inf"} —— 带 join @{verbatim "\<squnion>"} 或 meet @{verbatim "\<sqinter>"}
\item @{verbatim "lattice"} —— 两者兼有
\item @{verbatim "distrib_lattice"} —— 分配律
\item @{verbatim "linordered_set"} —— 线性 + 良序
\item @{verbatim "complete_lattice"} —— 任意集合都有 @{verbatim "Sup"} / @{verbatim "Inf"}
\item @{verbatim "complete_linorder"} —— 顶+底 (@{verbatim "top"}/@{verbatim "bot"}) 都存在
\end{itemize}

@{verbatim "bool"}、@{verbatim "nat"}、@{verbatim "int"}、@{verbatim "real"}、
@{verbatim "'a set"}、@{verbatim "'a list"}（字典序）都在树里挂好。\<close>

ML \<open>writeln "==== 30 开始 ===="\<close>

subsection \<open>30.2 最小公共接口：@{verbatim "ord"} 与 @{verbatim "less_eq"}\<close>

text \<open>所有序类都建立在两条常量上：@{verbatim "less_eq :: 'a \<Rightarrow> 'a \<Rightarrow> bool"}
（中缀 @{verbatim "\<le>"}）与 @{verbatim "less :: 'a \<Rightarrow> 'a \<Rightarrow> bool"}（@{verbatim "<"}）。
@{verbatim "order"} 类把它们绑成 @{verbatim "a < b \<equiv> a \<le> b \<and> \<not> b \<le> a"}。\<close>

thm order_less_le

subsection \<open>30.3 良序：@{verbatim "nat"} 上的 @{verbatim "<"}\<close>

text \<open>@{verbatim "nat"} 是 @{verbatim "wellorder"}：任何非空集合有最小元。
@{verbatim "wf_less"} 说 @{verbatim "<"} 是良基关系——第 15 章的良基递归就靠这条。
（@{verbatim "'a list"} 上的 @{verbatim "lex_less"} 也是良基的，但没进
默认 @{verbatim "ord"} 实例。）\<close>

thm wf_less

subsection \<open>30.4 格：@{verbatim "min"}/@{verbatim "max"} 与 @{verbatim "inf"}/@{verbatim "sup"}\<close>

text \<open>在 @{verbatim "linorder"} 上，@{verbatim "inf = min"}、@{verbatim "sup = max"}。
在集合上，@{verbatim "inf = \<inter>"}、@{verbatim "sup = \<union>"}。这两组"看起来不同"
其实是同一个类 @{verbatim "\<sqinter>"}/@{verbatim "\<squnion>"} 在不同类型上的实例。\<close>

value "min (5::nat) 3"
value "max (5::nat) 3"

lemma "inf ({1,2,3}::nat set) {2,3,4} = {2,3}" by auto
lemma "sup ({1,2,3}::nat set) {2,3,4} = {1,2,3,4}" by auto

lemma "min (5::nat) 3 = 3" by simp
lemma "max (5::nat) 3 = 5" by simp

subsection \<open>30.5 分配格律：@{verbatim "distrib_lattice"}\<close>

text \<open>@{verbatim "distrib_lattice"} 送出 @{verbatim "inf_distrib"}、
@{verbatim "sup_distrib"}。在集合上就是常见的 @{verbatim "A \<inter> (B \<union> C) =
(A \<inter> B) \<union> (A \<inter> C)"}；在 nat 上是 @{verbatim "min a (max b c) =
max (min a b) (min a c)"}。\<close>

thm inf_sup_distrib1
thm sup_inf_distrib1

lemma "({1,2}::nat set) \<inter> ({3,4} \<union> {5}) = ({1,2} \<inter> {3,4}) \<union> ({1,2} \<inter> {5})" by simp

subsection \<open>30.6 完备格：@{verbatim "Sup"}/@{verbatim "Inf"}\<close>

text \<open>@{verbatim "complete_lattice"} 加了"任意集合都有上确界/下确界"两条：
@{verbatim "Sup :: 'a set set \<Rightarrow> 'a"}、@{verbatim "Inf :: _ \<Rightarrow> _"}。
在 @{verbatim "'a set"} 上，@{verbatim "Sup A"} 就是 @{verbatim "\<Union>A"}。\<close>

lemma "Sup {{1::nat,2}, {3,4}} = {1,2,3,4}" by (auto simp add: Sup_set_def)
lemma "Inf {{1::nat,2,3}, {1,2,4}} = {1,2}" by (auto simp add: Inf_set_def)

subsection \<open>30.7 单调性：@{verbatim "mono"} 谓词\<close>

text \<open>@{verbatim "mono f"} 是 @{verbatim "\<forall>x y. x \<le> y \<longrightarrow> f x \<le> f y"}。
它是序类里"保持结构"的最小要求。若两端都保持，叫 @{verbatim "mono_both"}；
反向保持叫 @{verbatim "antitone"}。\<close>

definition f_double :: "nat \<Rightarrow> nat" where "f_double x = 2 * x"

lemma mono_f_double: "mono f_double"
  unfolding mono_def f_double_def by (intro allI impI) arith

definition f_pred :: "nat \<Rightarrow> nat" where "f_pred x = (if x = 0 then 0 else x - 1)"

lemma mono_f_pred: "mono f_pred"
  unfolding mono_def f_pred_def by (intro allI impI) auto

subsection \<open>30.8 上下界类：@{verbatim "bot"} / @{verbatim "top"}\<close>

text \<open>@{verbatim "order_bot"} 加了常量 @{verbatim "bot :: 'a"} 与律 @{verbatim "bot \<le> x"}；
@{verbatim "order_top"} 对称。HOL 里 @{verbatim "nat"} 有 @{verbatim "bot = 0"}
但没有 @{verbatim "top"}；@{verbatim "bool"} 有 @{verbatim "bot = False"} 与
@{verbatim "top = True"}。\<close>

value "(bot::nat)"
value "(bot::bool)"
value "(top::bool)"

thm bot_least
thm top_greatest

subsection \<open>30.9 给自定义类型装序：@{verbatim "instantiation"}\<close>

text \<open>把第 4 章的 @{verbatim "colour"} 数据型按 @{verbatim "Red < Green < Blue"}
排起来，一次 @{verbatim "instantiation colour :: linorder"} 就要提供
@{verbatim "less_eq_colour"} 与 @{verbatim "less_colour"}，
并证明反对称、传递、完全三条。\<close>

datatype colour = Red | Green | Blue

instantiation colour :: linorder
begin

definition less_eq_colour :: "colour \<Rightarrow> colour \<Rightarrow> bool" where
  "x \<le> (y::colour) \<longleftrightarrow>
    (case x of Red \<Rightarrow> True | Green \<Rightarrow> y \<noteq> Red | Blue \<Rightarrow> y = Blue)"

definition less_colour :: "colour \<Rightarrow> colour \<Rightarrow> bool" where
  "x < (y::colour) \<longleftrightarrow> (x \<le> y & \<not> y \<le> x)"

instance
  by standard
     (auto simp: less_eq_colour_def less_colour_def split: colour.splits)

end

value "(Red::colour) < Green"
value "(Blue::colour) < Green"
value "min Green (max Red Blue) = (Green::colour)"

subsection \<open>30.10 常用引理与工具\<close>

text \<open>序类送出一大批通用引理，与 @{verbatim "order"} 类型无关：\<close>

thm order_trans
thm order_antisym
thm le_less
thm linorder_linear

text \<open>@{verbatim "linorder_cases"} 是常用消去规则：给 @{verbatim "a < b"}, @{verbatim "a = b"},
@{verbatim "a > b"} 三种分支。\<close>

lemma fixes a b :: nat shows "a \<le> b | b < a"
  by arith

ML \<open>writeln "==== 30 结束 ===="\<close>

end
