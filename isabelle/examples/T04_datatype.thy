theory T04_datatype
  imports Main
begin

section \<open>4.1 datatype：自定义数据\<close>

text \<open>@{verbatim "datatype"} 一次性给出：类型、构造器、构造器参数类型、
归纳原理、case 分析原理、化简规则。它是 HOL 的核心定义机制。\<close>

ML \<open>writeln "==== 04 开始 ===="\<close>

subsection \<open>4.2 枚举与积型：形状与选项\<close>

datatype color = Red | Green | Blue

datatype 'a option = None | Some 'a

value "Blue"
value "color.Red = Red"
value "Some (3::nat)"
value "None :: nat option"

text \<open>@{verbatim "option"} 就是标准库里的"可空"：@{verbatim "None"}
表示缺失，@{verbatim "Some x"} 表示有值。函数库里的 @{verbatim "hd"}
对空表会炸，而返回 @{verbatim "'a option"} 的版本安全——
第 10 章用它做安全查表。\<close>

fun safe_hd :: "'a list \<Rightarrow> 'a option" where
  "safe_hd [] = None"
| "safe_hd (x # _) = Some x"

value "safe_hd ([]::nat list)"
value "safe_hd [10::nat, 20]"

subsection \<open>4.3 递归 datatype：表达式与树\<close>

datatype 'a tree = Leaf | Node "'a tree" 'a "'a tree"

fun mirror :: "'a tree \<Rightarrow> 'a tree" where
  "mirror Leaf = Leaf"
| "mirror (Node l x r) = Node (mirror r) x (mirror l)"

fun size_tree :: "'a tree \<Rightarrow> nat" where
  "size_tree Leaf = 0"
| "size_tree (Node l _ r) = 1 + size_tree l + size_tree r"

value "mirror (Node Leaf (1::nat) (Node Leaf 2 Leaf))"

lemma mirror_size: "size_tree (mirror t) = size_tree t"
  by (induction t) auto

subsection \<open>4.4 case 表达式与模式匹配\<close>

text \<open>case 不限于函数定义，任何项里都能用。分支必须穷尽，
否则 Isabelle 直接报 @{verbatim "not exhaustive"}。\<close>

value "(case Red of Red \<Rightarrow> (1::nat) | Green \<Rightarrow> 2 | Blue \<Rightarrow> 3)"
value "(case Some (5::nat) of None \<Rightarrow> (0::nat) | Some n \<Rightarrow> n)"
value "(case Node Leaf (7::nat) Leaf of Leaf \<Rightarrow> 0 | Node _ x _ \<Rightarrow> x)"

text \<open>@{verbatim "_"} 是不关心模式。模式里也可以嵌套构造器，
但教程建议只在分支顶层嵌套，浅模式配 @{verbatim "case"}，
深模式配 @{verbatim "fun"}。\<close>

subsection \<open>4.5 互递归 datatype：森林与树\<close>

datatype 'a forest = NilF | ConsF "'a tree" "'a forest"

fun trees :: "'a forest \<Rightarrow> nat" where
  "trees NilF = 0"
| "trees (ConsF t f) = size_tree t + trees f"

value "trees (ConsF (Node Leaf (1::nat) Leaf) NilF)"

subsection \<open>4.6 datatype 送给你的四件套\<close>

text \<open>每个 datatype 自动获得：
(1) 构造器注入性/互异性定理 @{verbatim "tree.simps"}；
(2) case 分析 @{verbatim "tree.split"}；
(3) 归纳 @{verbatim "tree.induct"}；
(4) 递归器的化简规则。
下面打印其中两条实测。\<close>

ML \<open>
  writeln (@{make_string} (hd @{thms tree.simps}));
  writeln (@{make_string} (hd @{thms option.simps}))
\<close>

lemma injective: "Node l1 (x::nat) r1 = Node l2 x r2 \<Longrightarrow> l1 = l2"
  by simp

ML \<open>writeln "==== 04 结束 ===="\<close>

end
