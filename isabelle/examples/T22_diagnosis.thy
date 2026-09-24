theory T22_diagnosis
  imports Main
begin

section \<open>22.1 看清楚目标状态\<close>

ML \<open>writeln "==== 22 开始 ===="\<close>

text \<open>证明卡住时，第一件事不是换方法，而是把目标**显示全**。
下面几个 (@{verbatim "[[ ]]"}) 选项控制 Isabelle 怎么打印东西：

@{verbatim "show_types"} —— 打印每个项的类型。这是最有用的一个：
绝大多数"两个东西看起来一样就是证不出来"其实是类型不同

@{verbatim "show_sorts"} —— 打印类型变量的类约束

@{verbatim "show_brackets"} —— 打印全部括号，看优先级到底怎么落的

@{verbatim "long_names"} —— 打印全限定名，而不是短名

@{verbatim "goals_limit"} —— 打印多少个目标（默认 10）

@{verbatim "eta_contract"} —— 是否把 @{verbatim "\<lambda>x. f x"} 折叠成 @{verbatim "f"}

打开 @{verbatim "show_types"} 之后，同一个定理会长成下面那样——注意
@{verbatim "_"} 位置上的类型标注：\<close>

lemma diag_demo: "length (xs @ ys) = length xs + length ys"
  by (rule length_append)

declare [[show_types = true]]

thm diag_demo

declare [[show_types = false]]

subsection \<open>22.2 find_theorems：按形状找定理\<close>

text \<open>@{verbatim "find_theorems"} 按**项的形状**匹配，下划线是通配：
@{verbatim "_"} 匹配任意项（不是匹配任意参数个数）。配合限定词
@{verbatim "(intro)"} @{verbatim "(elim)"} @{verbatim "(simp)"} @{verbatim "(dest)"}
可以按属性筛，@{verbatim "name:"} 按名字子串筛。\<close>

find_theorems "_ @ [] = _"
find_theorems "_ = rev (rev _)"
find_theorems name: "length" "length (_ @ _) = _"

subsection \<open>22.3 穷举：try0 与 solve_direct\<close>

text \<open>@{verbatim "try0"} 会用一串标准方法轮着试一遍，告诉你哪个成了；
@{verbatim "try"} 在此之外还会叫 @{verbatim "sledgehammer"}（慢得多，
会拉起外部 ATP）。 @{verbatim "solve_direct"} 检查你的目标是不是已经
有一条现成定理直接就是它。

它们的输出里有时间信息，本教程把它们放在**标记区间之外**——不是因为
不重要，而是因为"跑得快不快"不该进逐字节比对。\<close>

subsection \<open>22.4 反例、溢出与退化目标\<close>

text \<open>三类常见问题各有各的报错味道：

\begin{itemize}
\item @{verbatim "quickcheck"} 找不到反例不代表命题成立——它只是没找到；
      真正安全的是 @{verbatim "nitpick"}（穷尽有限模型），但它需要
      独立的外部求解器。
\item @{verbatim "Wellsortedness error"}：类型约束推不出来，通常是一串
      数字字面量没有足够信息定类型（本书第 3 章的坑）。
\item @{verbatim "Vacuous truth"} / @{verbatim "Illegal schematic variable"}：
      目标里有别的量化变量溜进来了，往往是 @{verbatim "induction"} 没写
      @{verbatim "arbitrary:"}，或者漏了 @{verbatim "\<And>"} 前缀。
\end{itemize}

真要查"这个目标在证明脚本的某一行到底长什么样"，用 @{verbatim "print_state"}、
以及后面提到的追踪开关。\<close>

subsection \<open>22.5 常见错误消息速查\<close>

text \<open>

@{verbatim "Inner lexical error"} / @{verbatim "Malformed command syntax"}
——源里出现了 Isabelle 不认的字符或符号写法。最常见的原因是直接写了
Unicode 符号（@{verbatim "\<forall>"}、@{verbatim "\<lbrakk>"}）而不是 ASCII 转义。

@{verbatim "Bad arguments for document antiquotation"} —— @{verbatim "verbatim"}
的参数忘了加 ASCII 引号。要显示的内容必须写成带引号的参数；
写成裸标识符就会触发这条报错。

@{verbatim "Undefined constant"} / @{verbatim "Bad type name"}
—— 拼错、或者要用 @{verbatim "Complex_Main"} 里的东西却只导入了 @{verbatim "Main"}。

@{verbatim "Not a logical constant"} —— 对一个其实不是常量的东西用了
常量 antiquotation（比如 @{verbatim "length"} 只是 @{verbatim "size"} 的缩写）。

@{verbatim "Type unification failed"} —— 两个类型对不上，多半是把列表写成
元组、或者 @{verbatim "::"} 标错了位置。

@{verbatim "No type arity"} —— 某个类型不属于某个类型类，比如拿函数类型
当 @{verbatim "enum"} 用。

@{verbatim "Failed to apply initial proof method"} —— @{verbatim "proof"}
后面那个开局方法就没接住目标，通常是归纳对象选错了。

@{verbatim "No subgoals!"} —— 目标已经被前面的 @{verbatim "apply (auto ...)"}
解决了，又多写了一步。 @{verbatim "auto"} 是对**全部**目标生效的。

@{verbatim "Failed to parse prop"} —— 语法层面的失败，但位置常常指向 RHS
而不是真凶。真凶在多数例子里是**名字本身**（第 18 章的
@{verbatim "SUM"} 事件：词法层的缩写替换）。

@{verbatim "At command <malformed>"} —— 上一处文本块的起止标记没配对：
多写一个结束标记会让后面的命令全部失认，而报错地点远在几十行之后。

@{verbatim "Draft FAILED / Unfinished session(s)"} —— 会话没建成。
先看有没有理论漏 @{verbatim "end"}，再看是第一处报错在哪。\<close>

ML \<open>writeln "==== 22 结束 ===="\<close>

text \<open>以下是故意放在比对区间之外的诊断演示：它们会打印时间、
重写步骤之类的易变信息。真要自己复现，把这几行剪切到你的草稿理论里跑。

@{verbatim "declare [[simp_trace = true]]"}

@{verbatim "declare [[simp_trace_depth_limit = 4]]"}

再证一条 @{verbatim "by simp"} 的目标，就能看到 simplifier 每一步
用了哪条规则、注意 @{verbatim "apply_trace"} 同理适用于 @{verbatim "rule"}。\<close>

end
