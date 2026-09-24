theory T05_recursion
  imports Main
begin

section \<open>5.1 递归的多种写法与终止性\<close>

text \<open>@{verbatim "fun"} 必须让机器相信"递归总会终止"。
结构递归（参数在变小）自动通过；非结构递归要给出度量函数。\<close>

ML \<open>writeln "==== 05 开始 ===="\<close>

subsection \<open>5.2 primrec：最原始的结构递归\<close>

primrec sum_to :: "nat \<Rightarrow> nat" where
  "sum_to 0 = 0"
| "sum_to (Suc n) = Suc n + sum_to n"

text \<open>@{verbatim "primrec"} 只接受结构递归，否则定义阶段直接报错。
它比 @{verbatim "fun"} 严格，也因此从不需要终止性证明。\<close>

value "sum_to (10::nat)"

subsection \<open>5.3 fun：结构递归的默认选择\<close>

fun app3 :: "'a list \<Rightarrow> 'a list \<Rightarrow> 'a list \<Rightarrow> 'a list" where
  "app3 [] ys zs = ys @ zs"
| "app3 (x # xs) ys zs = x # app3 xs ys zs"

value "app3 [1::nat] [2, 3] [4]"

subsection \<open>5.4 非结构递归：half 与度量函数\<close>

fun half :: "nat \<Rightarrow> nat" where
  "half 0 = 0"
| "half (Suc 0) = 0"
| "half (Suc (Suc n)) = Suc (half n)"

text \<open>@{verbatim "half"} 每次递归少 2，不是结构递归（ Suc (Suc n) 与
生成器的形状不一致），Isabelle 会自动尝试度量并报告
@{verbatim "Found termination order"}——这就是它"想明白了"的痕迹。\<close>

fun gcd2 :: "nat \<Rightarrow> nat \<Rightarrow> nat" where
  "gcd2 m 0 = m"
| "gcd2 m (Suc n) = gcd2 (Suc n) (m mod Suc n)"

text \<open>@{verbatim "gcd2"} 的终止性靠 @{verbatim "mod"} 变小，机器仍能自动找到。
找不到时会退回交互模式：先 @{verbatim "fun"} 给出带前提的方程，
再用 @{verbatim "termination"} 加度量补证——第 16 章展开全套流程。\<close>

value "gcd2 1071 462"

subsection \<open>5.5 观察 fun 送给你的化简规则与归纳原理\<close>

ML \<open>
  writeln (@{make_string} (hd @{thms half.simps}));
  writeln (@{make_string} (hd (tl (tl @{thms half.simps}))))
\<close>

lemma half_twice: "half (n + n) = n"
  by (induction n) simp_all

text \<open>为什么这一条能一行过？因为 @{verbatim "half.simps"} 在化简器里，
@{verbatim "2 * Suc n"} 被 @{verbatim "mult_Suc"} 类规则展开后
恰好撞进 @{verbatim "half"} 的方程。化简器的工作方式在第 7 章拆开讲。\<close>

subsection \<open>5.6 再练一遍：嵌套递归 datatype 的翻转对合\<close>

datatype 'a my_tree = Leaf | Node "'a my_tree" 'a "'a my_tree"

fun my_mirror :: "'a my_tree \<Rightarrow> 'a my_tree" where
  "my_mirror Leaf = Leaf"
| "my_mirror (Node l x r) = Node (my_mirror r) x (my_mirror l)"

value "my_mirror (Node Leaf (1::nat) (Node Leaf 2 Leaf))"

lemma my_mirror_twice: "my_mirror (my_mirror t) = t"
  by (induction t) auto

ML \<open>writeln "==== 05 结束 ===="\<close>

end
