theory T23_engineering
  imports Main
begin

section \<open>23.1 写给别人看的证明\<close>

ML \<open>writeln "==== 23 开始 ===="\<close>

text \<open>机器上"能过"的证明和人读得懂的证明是两回事。 @{verbatim "by auto"}
在探索阶段无可替代——它告诉你这条路走得通。但它不适合当归档形式：
一旦定义微调， @{verbatim "auto"} 的失败信息是一堆与你无关的中间状态。

本节用同一组小例子演示：怎么用探索式证明找路，再把它落成稳定、
可读、失败时能定位的形式。\<close>

subsection \<open>23.2 一条普通引理的两种写法\<close>

fun count :: "nat \<Rightarrow> nat list \<Rightarrow> nat" where
  "count x [] = 0"
| "count x (y # ys) = (if x = y then 1 else 0) + count x ys"

lemma count_append: "count x (xs @ ys) = count x xs + count x ys"
  by (induction xs) (auto simp: add.assoc add.commute add.left_commute)

text \<open>上面这条依赖" @{verbatim "auto"} 恰好能把加法重排对"。把同样的证明
写成带 @{verbatim "case"} 的形式，结构就显式了：\<close>

lemma count_append_isar: "count x (xs @ ys) = count x xs + count x ys"
proof (induction xs)
  case Nil
  then show ?case by simp
next
  case (Cons a xs)
  then show ?case by (simp add: add.assoc add.left_commute add.commute)
qed

text \<open>注意 @{verbatim "add.assoc"}、@{verbatim "add.left_commute"}、
@{verbatim "add.commute"} 这三个：它们是"交换半群重排"的标准三件套，
比 @{verbatim "auto"} 猜方向来得可靠—— @{verbatim "auto"} 也可能用
@{verbatim "linarith"} 硬算，那就把这步变成"看机器有多大内存"。\<close>

subsection \<open>23.3 该引理就引理，别堆在一个证里\<close>

lemma count_le_length: "count x xs \<le> length xs"
  by (induction xs) auto

text \<open>再用它去证"两次计数不超过两段长度之和"：如果把它和
@{verbatim "count_append"} 一起塞进一个 @{verbatim "proof"}，
失败时你分不清是哪一半错了。\<close>

lemma count_append_le: "count x (xs @ ys) \<le> length xs + length ys"
proof -
  have "count x (xs @ ys) = count x xs + count x ys" by (rule count_append)
  also have "... \<le> length xs + length ys"
    using count_le_length count_le_length[of x ys] by (rule Nat.add_le_mono)
  finally show ?thesis .
qed

text \<open>@{verbatim "also ... finally"} 在这里不只是好看：每一行的中间结论
都被独立检查，类型与方向错了立刻知道是哪一步。\<close>

subsection \<open>23.4 把东西先局部化\<close>

text \<open>只想临时引进一个参数做推理时，不必定义 locale：裸
@{verbatim "context fixes ... begin ... end"} 就够。出了 @{verbatim "end"}，
里面的定理会被自动泛化，之前 @{verbatim "fixes"} 进来的变量变成显式的
全称量词——和 locale 背后是同一套机制，只是省掉了命名。\<close>

context
  fixes k :: nat
begin

definition plus_k :: "nat \<Rightarrow> nat" where
  "plus_k n = n + k"

lemma plus_k_ge: "n \<le> plus_k n"
  by (simp add: plus_k_def)

end

thm plus_k_ge

text \<open>看 @{verbatim "plus_k_ge"} 的输出： @{verbatim "k"} 已经变成了显式的参数。
这是 locale 背后同一套机制，只是省掉了命名。\<close>

subsection \<open>23.5 属性的加加减减\<close>

text \<open>最后几条经验：

\begin{itemize}
\item 只要还要用 @{verbatim "simp add: X"}，就别把 @{verbatim "declare X [simp]"}
      写成全局——同一个 @{verbatim "X"} 在两个地方被需要，第三个地方会被误伤。
\item @{verbatim "[simp del]"} 不是"删掉"而是"从这一步开始不用"，次序很重要。
\item @{verbatim "lemmas foo = bar baz"} 可以把一组定理批量命名、批量打属性，
      比在每条 @{verbatim "lemma"} 上重复 @{verbatim "[simp]"} 好维护。
\item 归纳时间的指标函数最好单独命名（ @{verbatim "measure ..."} ），
      这样 @{verbatim "termination"} 失败时能看到具体恶化在哪。
\end{itemize}

@{verbatim "bundle"} 是这类"局部修改"的标准容器（见第 21 章）：
一批 @{verbatim "declare"} 可以随 @{verbatim "context includes B"} 开关，
不留下全局痕迹。\<close>

lemmas count_simps = count.simps
lemmas count_rules = count_append count_append_isar

ML \<open>writeln "==== 23 结束 ===="\<close>

end
