theory T24_capstone
  imports Main
begin

section \<open>24.1 最后一座：表达式编译器\<close>

ML \<open>writeln "==== 24 开始 ===="\<close>

text \<open>这一章把前面二十几章的东西串起来做成一件完整的事：
定义一门源语言（算术表达式）、一台目标机器（栈机）、一个编译器，
然后证明**编译器正确**——编译出来的指令序列，执行效果等于源语言的语义。

它同时用到：数据类型（第 4 章）、递归函数（第 5 章）、
结构化归纳（第 6 章）、 @{verbatim "simp"} 与 @{verbatim "auto"} 的配合
（第 7、8 章）、 @{verbatim "arbitrary:"}（第 6 章），以及代码生成
（第 19 章）。\<close>

subsection \<open>24.2 源语言\<close>

type_synonym vname = string
type_synonym state = "vname \<Rightarrow> int"

datatype aexp = N int | V vname | Plus aexp aexp

fun aval :: "aexp \<Rightarrow> state \<Rightarrow> int" where
  "aval (N n) s = n"
| "aval (V x) s = s x"
| "aval (Plus a1 a2) s = aval a1 s + aval a2 s"

value "aval (Plus (V ''x'') (N 5)) ((\<lambda>x. 0) (''x'' := 3))"

subsection \<open>24.3 目标机器：栈机\<close>

datatype instr = LOADI int | LOAD vname | ADD

type_synonym stack = "int list"

text \<open>指令序列从左到右执行，栈也按"栈顶在左"的惯例写。
加法 @{verbatim "ADD"} 弹出栈顶两个元素，压回它们的和。
这里刻意用 @{verbatim "hd"} / @{verbatim "tl"} 而不是模式匹配：
模式匹配会逼你给"栈深度不足"这种畸形状态一个返回值，
而那本来就是不该发生的事，凭空引入一个 @{verbatim "undefined"} 分支
只会污染后续证明。\<close>

fun exec :: "instr list \<Rightarrow> state \<Rightarrow> stack \<Rightarrow> stack" where
  "exec [] s stk = stk"
| "exec (i # is) s stk = (case i of
     LOADI n \<Rightarrow> exec is s (n # stk)
   | LOAD x  \<Rightarrow> exec is s (s x # stk)
   | ADD     \<Rightarrow> exec is s ((hd (tl stk) + hd stk) # tl (tl stk)))"

value "exec [LOADI 3, LOADI 4, ADD] (\<lambda>x. 0) []"

subsection \<open>24.4 编译器\<close>

fun compile :: "aexp \<Rightarrow> instr list" where
  "compile (N n) = [LOADI n]"
| "compile (V x) = [LOAD x]"
| "compile (Plus a1 a2) = compile a2 @ compile a1 @ [ADD]"

value "compile (Plus (N 3) (V ''x''))"

subsection \<open>24.5 第一条：执行是可拼接的\<close>

text \<open>这条 @{verbatim "exec_append"} 是整章的关键引理：
它把"拼接执行"变成"连续执行"。没有它，归纳步骤里会出现一长串
无法化简的 @{verbatim "@"}。

注意 @{verbatim "arbitrary: stk"}：归纳时的栈在每一步都不同，
不把它设为任意，归纳假设会被特化到某一个栈上，用不上。\<close>

lemma exec_append: "exec (is1 @ is2) s stk = exec is2 s (exec is1 s stk)"
  apply (induction is1 arbitrary: stk s)
    apply simp
   apply (auto split: instr.split)
  done

subsection \<open>24.6 编译正确性\<close>

theorem exec_compile: "exec (compile a) s stk = aval a s # stk"
proof (induction a arbitrary: stk)
  case (N n)
  then show ?case by simp
next
  case (V x)
  then show ?case by simp
next
  case (Plus a1 a2)
  then show ?case by (simp add: exec_append add.commute)
qed

text \<open>三个分支各说一件事：常量就是压一个立即数、变量就是加载、
加法则"先执行左段的编译结果，再在其上执行右段，最后 ADD"。
@{verbatim "add.commute"} 出现在最后一步，是因为栈是"反的"：
栈顶放着右子表达式的值。\<close>

subsection \<open>24.7 再进一步：一个常量折叠优化\<close>

text \<open>正确性定理一旦立住，就可以拿它验证"改写源程序"是安全的。
下面这个 @{verbatim "optm"} 把源树里相邻的两个常量先算掉。\<close>

fun optm :: "aexp \<Rightarrow> aexp" where
  "optm (N n) = N n"
| "optm (V x) = V x"
| "optm (Plus a1 a2) = (case (optm a1, optm a2) of
     (N m, N n) \<Rightarrow> N (m + n)
   | (b1, b2) \<Rightarrow> Plus b1 b2)"

lemma aval_optm: "aval (optm a) s = aval a s"
  apply (induction a)
    apply simp
   apply simp
  apply (auto split: aexp.split)
  done

value "optm (Plus (Plus (N 1) (N 2)) (V ''x''))"

text \<open>把优化和正确性定理串起来，就得到"优化不改变机器行为"：\<close>

lemma optm_preserves_machine: "exec (compile (optm a)) s stk = exec (compile a) s stk"
  by (simp add: exec_compile aval_optm)

subsection \<open>24.8 收尾：导出一台能跑的机器\<close>

export_code aval compile exec optm in SML module_name T24_Machine

text \<open>到这一步，这台机器已经不是一个比喻了：它是可以编出来、
可以跑、并且被证明过的东西。这也是本书想留给读者的方法论——

\begin{enumerate}
\item 先把对象语言写成 @{verbatim "datatype"}，把语义写成 @{verbatim "fun"}；
\item 先证**结构性质**（拼接、结合、交换），再证主定理；
\item 主定理用归纳，归纳变量但凡会变都写 @{verbatim "arbitrary:"}；
\item 每个 @{verbatim "simp"} 步骤问一句"它凭什么知道这个"；
\item 最后 @{verbatim "export_code"}，让证明过的东西真的跑起来。
\end{enumerate}\<close>

ML \<open>writeln "==== 24 结束 ===="\<close>

end
