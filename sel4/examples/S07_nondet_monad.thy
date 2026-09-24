theory S07_nondet_monad
  imports Main "HOL-Library.Monad_Syntax"
begin

section \<open>7.1 读 l4v 的第一道门槛：非确定性状态单子\<close>

text \<open>
  seL4 规范里几乎每个内核函数都长这样：

  @{verbatim "get_cap :: cslot_ptr => (cap,'z::state_ext) s_monad"}

  类型 @{verbatim "s_monad"} 是 \emph{非确定性状态单子}。真实定义在
  @{verbatim "l4v/lib/Monads/nondet/Nondet_Monad.thy"} 第 36 行：

  @{verbatim "type_synonym ('s,'a) nondet_monad = 's => ('a * 's) set * bool"}

  拆开看三层：
  \begin{itemize}
    \item 输入一个状态 @{verbatim "s"}；
    \item 输出一\emph{集合}个"结果 + 新状态"对——集合有 0 个、1 个或多个元素，
          分别对应"此路不通""确定性的""有多种可能"；
    \item 外加一个 @{verbatim "bool"}：@{verbatim "True"} 表示\emph{失败}
          （对应 @{verbatim "fail"}），它和"返回空集"是两回事。
  \end{itemize}

  为什么要有集合：内核里确实有不确定行为——revoke 挑哪一个子孙先删、
  @{verbatim "select_ext"} 挑哪个中断先处理。规范\emph{不承诺顺序}，
  于是"所有可能结果"都要被推理覆盖。@{verbatim "l4v/spec/abstract/Deterministic_A.thy"}
  整章就是在讲：什么时候这一层不确定性可以被压平成确定性。
\<close>

ML \<open>writeln "==== 07 开始 ===="\<close>

type_synonym ('s,'a) nondet = "'s \<Rightarrow> (('a \<times> 's) set \<times> bool)"

definition kreturn :: "'a \<Rightarrow> ('s,'a) nondet" where
  "kreturn x \<equiv> \<lambda>s. ({(x, s)}, False)"

definition kbind :: "('s,'a) nondet \<Rightarrow> ('a \<Rightarrow> ('s,'b) nondet) \<Rightarrow> ('s,'b) nondet" where
  "kbind m f \<equiv> \<lambda>s. (\<Union>p \<in> fst (m s). fst (f (fst p) (snd p)),
                    snd (m s) \<or> (\<exists>p \<in> fst (m s). snd (f (fst p) (snd p))))"

adhoc_overloading bind == kbind

definition kfail :: "('s,'a) nondet" where
  "kfail \<equiv> \<lambda>s. ({}, True)"

definition kassert :: "bool \<Rightarrow> ('s,unit) nondet" where
  "kassert P \<equiv> if P then kreturn () else kfail"

definition kassert_opt :: "'a option \<Rightarrow> ('s,'a) nondet" where
  "kassert_opt v \<equiv> case v of None \<Rightarrow> kfail | Some x \<Rightarrow> kreturn x"

definition kget :: "('s,'s) nondet" where
  "kget \<equiv> \<lambda>s. ({(s, s)}, False)"

definition kput :: "'s \<Rightarrow> ('s,unit) nondet" where
  "kput s' \<equiv> \<lambda>s. ({((), s')}, False)"

definition kgets :: "('s \<Rightarrow> 'a) \<Rightarrow> ('s,'a) nondet" where
  "kgets f \<equiv> \<lambda>s. ({(f s, s)}, False)"

definition kmodify :: "('s \<Rightarrow> 's) \<Rightarrow> ('s,unit) nondet" where
  "kmodify f \<equiv> \<lambda>s. ({((), f s)}, False)"

definition kselect :: "'a set \<Rightarrow> ('s,'a) nondet" where
  "kselect A \<equiv> \<lambda>s. (A \<times> {s}, False)"

definition kwhen :: "bool \<Rightarrow> ('s,unit) nondet \<Rightarrow> ('s,unit) nondet" where
  "kwhen P m \<equiv> if P then m else kreturn ()"

text \<open>
  上一节那串 @{verbatim "k"} 前缀只是为了避开 @{verbatim "Monad_Syntax"} 里那个
  泛型的 @{verbatim "bind"}。挂上 @{verbatim "adhoc_overloading"} 之后，
  就可以写 do 记号了：
\<close>

definition get_cap_twice :: "('s,'s) nondet" where
  "get_cap_twice \<equiv> do { s <- kget; t <- kget; kreturn s }"

definition inc :: "(nat,nat) nondet" where
  "inc \<equiv> do { n <- kget; kput (n + 1); kreturn n }"

ML \<open>writeln (@{make_string} @{thm inc_def})\<close>

subsection \<open>7.2 单子三定律\<close>

text \<open>
  这三条是"单子"这个词的含义，也是后续所有代数化简的依据。
  l4v 里对应的定理在 @{verbatim "Nondet_Monad.thy"} 第 208–225 行。
\<close>

lemma bind_return_left: "kbind (kreturn x) f = f x"
  by (rule ext) (auto simp: kbind_def kreturn_def)

lemma bind_return_right: "kbind m kreturn = m"
  by (rule ext) (auto simp: kbind_def kreturn_def)

lemma bind_fail_left: "kbind kfail f = kfail"
  by (rule ext) (auto simp: kbind_def kfail_def)

lemma assert_false_is_fail: "kassert False = kfail"
  by (simp add: kassert_def)

lemma assert_true_is_return: "kassert True = kreturn ()"
  by (simp add: kassert_def)

subsection \<open>7.3 结合律：这一条最啰嗦，也最值得证\<close>

text \<open>
  结合律说明"括号怎么加都无所谓"，于是 do 记号里的分号才能连成一串。
  证明里唯一的技术点是\emph{并集的扁平化}：
  @{term "(\<Union>p \<in> \<Union>q \<in> A. B q. C p)"} 与
  @{term "(\<Union>q \<in> A. \<Union>p \<in> B q. C p)"} 是同一个集合。
\<close>

lemma bind_assoc: "kbind (kbind m f) g = kbind m (\<lambda>x. kbind (f x) g)"
  by (rule ext) (auto simp: kbind_def split: prod.splits)

text \<open>
  失败标志那一位同样要结合：@{verbatim "snd"} 取的是"这一路是否失败过"，
  所以它是 @{verbatim "or"} 的嵌套——把嵌套拆开就是结合律的另一半。
\<close>

subsection \<open>7.4 失败与"空结果"是两件事\<close>

text \<open>
  这是 l4v 里最容易误解的设计。@{verbatim "fail"} 返回空结果集
  \emph{并且}把失败标志置真；而 @{verbatim "assert False"} 之外还有一类
  "正常返回但结果集为空"的情况（比如 @{verbatim "select {}"}）。

  后果很实际：@{verbatim "no_fail"} 这个谓词只看失败标志，
  与结果集是否为无关。
\<close>

definition no_fail :: "('s,'a) nondet \<Rightarrow> bool" where
  "no_fail m \<equiv> \<forall>s. \<not> snd (m s)"

definition nonempty :: "('s,'a) nondet \<Rightarrow> bool" where
  "nonempty m \<equiv> \<forall>s. fst (m s) \<noteq> {}"

lemma fail_fails: "\<not> no_fail kfail"
  by (simp add: no_fail_def kfail_def)

lemma select_empty_does_not_fail: "no_fail (kselect {})"
  by (simp add: no_fail_def kselect_def)

lemma select_empty_has_no_results: "\<not> nonempty (kselect {})"
  by (simp add: nonempty_def kselect_def)

lemma no_fail_bind:
  "no_fail m \<Longrightarrow> (\<forall>s x. no_fail (f x)) \<Longrightarrow> no_fail (kbind m f)"
  by (auto simp: no_fail_def kbind_def)

text \<open>
  @{thm no_fail_bind} 是 l4v 里 @{verbatim "no_fail"} 证明的骨架：
  要证明一大段内核代码不会失败，就把它拆成若干 @{verbatim "no_fail"} 的片段
  再用这条组合起来。真实代码里 @{verbatim "Nondet_No_Fail.thy"} 整篇都在做这件事。
\<close>

subsection \<open>7.5 状态操作的三条等式\<close>

lemma get_put_id: "kbind kget kput = kreturn ()"
  by (rule ext) (auto simp: kbind_def kget_def kput_def kreturn_def)

lemma gets_is_pure: "fst (kgets f s) = {(f s, s)}"
  by (simp add: kgets_def)

lemma modify_twice: "kbind (kmodify f) (\<lambda>_. kmodify g) = kmodify (g \<circ> f)"
  by (rule ext) (auto simp: kbind_def kmodify_def)

text \<open>
  最后一条里 @{verbatim "g \<circ> f"} 的顺序值得停一下：先 @{verbatim "f"} 后
  @{verbatim "g"}。内核代码里连续两次 @{verbatim "modify"} 被合并时，
  顺序搞反是最常见的笔误。
\<close>

subsection \<open>7.6 非确定性是怎么进到内核里的\<close>

text \<open>
  @{verbatim "kselect"} 会把一个集合整个变成"可能的结果"。真实内核用它表达
  @{verbatim "select_ext"}（@{verbatim "Nondet_Monad.thy"} 第 118 行的
  @{verbatim "select_f"}）与中断/调度顺序的不确定性。
\<close>

lemma select_singleton_is_return: "kselect {x} = kreturn x"
  by (rule ext) (auto simp: kselect_def kreturn_def)

lemma bind_select_collects:
  "fst (kbind (kselect A) (\<lambda>x. kreturn (x + (1::nat))) s) = (\<lambda>x. x + 1) ` A \<times> {s}"
  by (auto simp: kbind_def kselect_def kreturn_def)

text \<open>
  最后一条就是"把所有可能结果收集起来"的样子：do 记号里走一遍
  @{verbatim "kselect"}，出来的是一个集合。第 22 章证明信息流性质时，
  正是要说明\emph{这个集合里的每一个结果}都同样安全。
\<close>

ML \<open>
  writeln (@{make_string} @{thm bind_assoc});
  writeln (@{make_string} @{thm no_fail_bind})
\<close>

ML \<open>writeln "==== 07 结束 ===="\<close>

end
