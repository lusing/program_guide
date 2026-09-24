theory T15_relations_wf
  imports Main
begin

section \<open>15.1 关系、闭包与良基性\<close>

text \<open>关系是"二元谓词"：@{verbatim "'a rel = 'a ⇒ 'a ⇒ bool"}。
传递闭包 @{verbatim "rtrancl"} 是归纳定义的，因此有归纳原理——
这是证明"可达性"类性质的钥匙。\<close>

ML \<open>writeln "==== 15 开始 ===="\<close>

subsection \<open>15.2 关系的基本运算\<close>

value "{(1::nat, 2::nat), (2::nat, 3::nat)}"
value "{(1::nat, 2::nat)} O {(2::nat, 3::nat)}"
value "((1::nat, 2::nat) \<in> {(1::nat, 2::nat)})"

lemma relcomp_demo: "(r O s) `` A = s `` (r `` A)"
  by blast

subsection \<open>15.3 传递闭包的归纳原理\<close>

text \<open>@{verbatim "rtrancl"} 的归纳原理说：如果 @{verbatim "(x,y) ∈ r"}，
以及闭包对组合封闭，那么任何 @{verbatim "(x,z) ∈ r*"} 都成立。
打印出来看它长什么样。\<close>

ML \<open>writeln (@{make_string} @{thm rtrancl_induct})\<close>

lemma rtrancl_refl: "(a, a) \<in> r\<^sup>*"
  by (rule rtrancl_refl)

lemma rtrancl_into: "(a, b) \<in> r\<^sup>* \<Longrightarrow> (b, c) \<in> r \<Longrightarrow> (a, c) \<in> r\<^sup>*"
  by (rule rtrancl_into_rtrancl)

subsection \<open>15.4 良基关系：递归终止的理论依据\<close>

text \<open>良基（@{verbatim "wf"}）= 不存在无限下降链。所有良基关系都可以
做递归；@{verbatim "measure f"} 把"某个自然数量在下降"变成
良基关系，是我们最常用的度量手段。\<close>

lemma wf_less_than: "wf less_than"
  by simp

lemma wf_measure: "wf (measure f)"
  by simp

lemma measure_less: "((x, y) \<in> measure f) = (f x < f y)"
  by (simp add: measure_def)

subsection \<open>15.5 手写一次 termination 证明\<close>

text \<open>下面这个函数把"列表长度在下降"作为度量：\<close>

function count_down :: "nat list \<Rightarrow> nat" where
  "count_down [] = 0"
| "count_down (x # xs) = 1 + count_down xs"
  by pat_completeness auto
termination by (relation "measure length") auto

value "count_down [1::nat, 2, 3]"

text \<open>@{verbatim "termination"} 命令后面的证明就是在证
"每步递归都在 @{verbatim "measure length"} 里变小"：
目标变成 @{verbatim "((xs, x # xs) ∈ measure length)"}，
展开后是 @{verbatim "length xs < length (x # xs)"}，simp 直接过。\<close>

subsection \<open>15.6 一次失败的自动终止性（及手工救场）\<close>

text \<open>机器自动找度量失败时，会留下一条带前提的方程
@{verbatim "f.dom"}。这时要么手写度量（如上），要么
改用 @{verbatim "partial_function"}：它不要求终止，代价是
方程带 @{verbatim "dom"} 前提——第 16 章展开。\<close>

ML \<open>writeln "==== 15 结束 ===="\<close>

end
