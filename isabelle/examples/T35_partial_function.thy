theory T35_partial_function
  imports Main
begin

section \<open>35.1 fun 的天花板：不终止的"函数"\<close>

text \<open>functions 手册（functions.pdf）开头就划界：@{verbatim "fun"}/
@{verbatim "function"} 定义**全函数**——每个输入必须落在输出上，所以
定义本身要过终止性检查。实测被拒的样子（第 5 章的老朋友）：

```text
fun f where "f n = f n"
*** Unfinished subgoals:
*** Calls:
***   a) n ~> n
*** Result matrix:
*** Could not find lexicographic termination order.
```

但"搜第一个满足谓词的元素"这类**部分函数**是正当的数学对象：
找不到就是找不到（@{verbatim "None"}），不是错误。三种落地方式
——@{verbatim "partial_function (option)"}、@{verbatim "(tailrec)"}、
Main 里的 @{verbatim "while_option"}——本章逐一实测。\<close>

ML \<open>writeln "==== 35 开始 ===="\<close>

subsection \<open>35.2 第一个坑：partial_function 只吃单条方程\<close>

text \<open>@{verbatim "fun"} 的多方程竖线写法在这里**直接语法错误**
（实测报 @{verbatim "command expected, but keyword |"}）。
@{verbatim "partial_function"} 只接受**一条**方程，模式用 @{verbatim "case"}
折进去：\<close>

partial_function (option) findP where
  "findP p xs = (case xs of [] \<Rightarrow> None
     | x # xs' \<Rightarrow> if p x then Some x else findP p xs')"

text \<open>定义后的事实清单用 @{verbatim "find_theorems findP"} 看，
实测只有三条：@{verbatim "findP.simps"}（单条展开方程）、
@{verbatim "findP.raw_induct"}（泛函形状的归纳原理）、
@{verbatim "findP.fixp_induct"}（不动点语义，需 admissible）。
**没有** @{verbatim "findP.pinduct"}（实测 Undefined fact，
手册旧版本的提法），也没有 @{verbatim "fun"} 式的多条 simps。\<close>

find_theorems findP

subsection \<open>35.3 证明：结构归纳 + 逐步展开\<close>

text \<open>@{verbatim "raw_induct"} 的形状对 @{verbatim "induct rule:"}
极不友好（实测两种写法都配不上：结论参差、前提被错当结论）。好消息：
**尾递归**形状的部分函数（递归调用都在子结构上）用普通结构归纳 +
@{verbatim "findP.simps"} 展开就能证：\<close>

lemma findP_Some: "findP p xs = Some x \<Longrightarrow> x \<in> set xs"
proof (induct xs)
  case Nil thus ?case by (simp add: findP.simps)
next
  case (Cons y ys) thus ?case
    by (auto simp: findP.simps split: if_splits)
qed

text \<open>非尾递归（递归调用在构造器**里面**，如
@{verbatim "Some (f x + f y)"}）就得真用 @{verbatim "raw_induct"} 或
@{verbatim "fixp_induct"} 了——那时再回 functions 手册第 3 章。\<close>

subsection \<open>35.4 求值：code 方程要手动注册\<close>

text \<open>第二个坑：@{verbatim "partial_function"} 的方程默认**没有**
注册为代码方程。直接 @{verbatim "value"} 报
@{verbatim "No code equations for findP"}。注册一行解决：\<close>

declare findP.simps [code]

value "the (findP (\<lambda>n. n > 2) [(1::nat), 2, 3, 4])"

subsection \<open>35.5 tailrec 单子：累加器型循环\<close>

text \<open>@{verbatim "(tailrec)"} 装的是尾递归单子（同样在 HOL 里，
与 @{verbatim "(option)"} 并列注册）。适合累加器风格；返回值直接就是
结果类型（不套 @{verbatim "option"}），不终止时值是 @{verbatim "undefined"}：\<close>

partial_function (tailrec) sum_acc :: "nat \<Rightarrow> nat list \<Rightarrow> nat" where
  "sum_acc acc xs = (case xs of [] \<Rightarrow> acc | x # xs' \<Rightarrow> sum_acc (acc + x) xs')"

subsection \<open>35.6 手搓 while 组合子\<close>

text \<open>三个 lambda 都标了 @{verbatim "nat"}：少一个标注就留下多态约束，
@{verbatim "value"} 报 @{verbatim "not of sort"} 系列（第 3 章的老坑
换了件衣服）。顺带一个更阴的坑：**拼错/不存在的常量名不报错**——
被当成自由变量，@{verbatim "value"} 把你输入的项原样"求值"回来
（实测对 Library 里的 @{verbatim "while_option"}（**不在 Main！**）
就这么干过，打印出未展开的项、类型挂着 @{verbatim "'b"}）。
看到 value 输出以双引号包着原样项、类型是多态字母，先查常量在不在。

现成的 @{verbatim "while_option"} 在 HOL-Library 的
@{verbatim "While_Combinator"} 里（第 45 章）。这里用本章工具手搓一个：\<close>

partial_function (option) mywhile :: "('a \<Rightarrow> bool) \<Rightarrow> ('a \<Rightarrow> 'a) \<Rightarrow> 'a \<Rightarrow> 'a option" where
  "mywhile b c s = (if b s then mywhile b c (c s) else Some s)"

declare mywhile.simps [code]

value "mywhile (\<lambda>n. n \<noteq> (1::nat))
  (\<lambda>n. if even (n::nat) then n div 2 else 3 * n + 1) 6"

value "mywhile (\<lambda>n. n > (0::nat)) (\<lambda>n. n - 1) 3"

subsection \<open>35.7 重叠模式的 fun：一致就自动消歧\<close>

text \<open>@{verbatim "fun"} 的模式匹配是**顺序**的（从上到下试）。
两条方程重叠时，只要 RHS 在重叠处**取值一致**，包会自动算出
互斥的化简方程（实测 @{verbatim "Found termination order: {}"}，
@{verbatim "f.simps"} 是两条干净方程）；不一致则被拒：\<close>

fun f where
  "f (Suc n) = n"
| "f n = 0"

thm f.simps

text \<open>@{verbatim "f (Suc n) = n"} 与 @{verbatim "f 0 = 0"}
——第二条的 @{verbatim "n"} 实际只剩 @{verbatim "0"} 可匹配，
所以没有信息损失。若两条方程在重叠处取值**不一致**
（比如把第二条改成 @{verbatim "f n = n"}），模式检查直接拒绝定义。\<close>

subsection \<open>35.8 选型速查\<close>

text \<open>functions 手册 + 实测的决策树：

  - 能写成结构递归 → @{verbatim "primrec"}（第 5 章）；
  - 需要自动终止性 → @{verbatim "fun"}；
  - 终止要手证/非显见 → @{verbatim "function"} 加手证
    @{verbatim "termination"}（第 15/16 章）；
  - **可能不终止**且要"找不到就 None" → @{verbatim "partial_function (option)"}；
  - 不终止没意义但想要尾循环语义 → @{verbatim "(tailrec)"}、
    手搓 while（35.6）或 Library 的 @{verbatim "while_option"}（45 章）；
  - 逻辑上就是全函数但方程重叠 → @{verbatim "fun"} 能消歧就消歧
    （35.7），不能就改写模式。

与第 51 章的接口：@{verbatim "partial_function"} 的语义是
**最小不动点 + 容许性（admissible）**——Knaster--Tarski 的
@{verbatim "lfp"} 在 cpo 上的亲戚，那边会见到它的数学原型。\<close>

thm findP_Some

ML \<open>writeln "==== 35 结束 ===="\<close>

end
