theory S22_infoflow
  imports Main
begin

section \<open>22.1 机密性：非干扰\<close>

text \<open>
  完整性说"不能乱改"，机密性说"不能偷看"。seL4 的机密性定理叫
  \emph{非干扰（noninterference）}，位于
  @{verbatim "l4v/proof/infoflow/"}：核心文件是
  @{verbatim "Noninterference_Base.thy"}、@{verbatim "Noninterference.thy"}、
  @{verbatim "InfoFlow_IF.thy"}、@{verbatim "Ipc_IF.thy"}，
  还有 @{verbatim "ADT_IF.thy"}（把内核包装成一个带安全域的自动机）。

  定理的直觉形式：

  \begin{quote}
  把高安全级主体的一切输入"擦掉"（换成默认值）之后再跑一遍系统，
  低安全级主体看到的东西与原来完全一样。
  \end{quote}

  这个"擦掉"操作叫 @{verbatim "equiv_for"} / @{verbatim "uwr"}（unwinding
  relation），是整章的技术核心。
\<close>

ML \<open>writeln "==== 22 开始 ===="\<close>

type_synonym obj_ref = nat
type_synonym domain = nat

datatype level = Low | High

text \<open>
  注意：@{verbatim "record"} 的字段之间是空格/换行分隔，
  \emph{不是} @{verbatim "|"} —— @{verbatim "|"} 只用于
  @{verbatim "datatype"} 的构造子。这是新手最常踩的语法坑之一。
\<close>

record msg =
  m_to   :: obj_ref
  m_body :: nat

record kstate =
  ks_msgs :: "obj_ref \<Rightarrow> nat"
  ks_cur  :: obj_ref

subsection \<open>22.2 擦除：把高安全级的东西换成默认值\<close>

definition level_of :: "obj_ref \<Rightarrow> level" where
  "level_of p \<equiv> if p < 100 then Low else High"

definition erase_high :: "kstate \<Rightarrow> kstate" where
  "erase_high s \<equiv> s\<lparr> ks_msgs := \<lambda>p. if level_of p = High then 0 else ks_msgs s p \<rparr>"

lemma erase_touches_only_high:
  "level_of p = Low \<Longrightarrow> ks_msgs (erase_high s) p = ks_msgs s p"
  by (simp add: erase_high_def)

lemma erase_zeroes_high:
  "level_of p = High \<Longrightarrow> ks_msgs (erase_high s) p = 0"
  by (simp add: erase_high_def)

text \<open>
  注意这里要证明的是\emph{记录}相等，不是函数相等，
  所以 @{verbatim "rule ext"} 不好使（它只对函数生效）：
  得先把记录拆开再比较两个字段。
\<close>

lemma erase_is_idempotent: "erase_high (erase_high s) = erase_high s"
  by (cases s; simp add: erase_high_def fun_eq_iff)

subsection \<open>22.3 不可区分关系 uwr\<close>

text \<open>
  两个状态对某个观察者 d "不可区分"，当且仅当把它们都擦除之后
  d 能看到的完全一致。
\<close>

definition uwr :: "kstate \<Rightarrow> obj_ref \<Rightarrow> kstate \<Rightarrow> bool" where
  "uwr s d t \<equiv> ks_msgs (erase_high s) = ks_msgs (erase_high t)"

lemma uwr_reflexive: "uwr s d s"
  by (simp add: uwr_def)

lemma uwr_symmetric: "uwr s d t \<Longrightarrow> uwr t d s"
  by (simp add: uwr_def)

lemma uwr_transitive: "uwr s d t \<Longrightarrow> uwr t d u \<Longrightarrow> uwr s d u"
  by (simp add: uwr_def)

text \<open>
  @{thm uwr_transitive} 说明"不可区分"是个等价关系，
  于是"低观察者分不出两种高输入"可以被传递地使用。
  真实定义里 @{verbatim "uwr"} 的参数还包括观察者所在的域，
  这里简化掉了。
\<close>

subsection \<open>22.4 单步非干扰\<close>

text \<open>
  非干扰的归纳形式：每一步都保持不可区分 ⟹ 任意长的运行也保持。
  模型里"一步"就是一个简单的状态转移函数。
\<close>

text \<open>
  "一步"就是"当前线程给自己的信箱加一，然后换下一个线程"。
  真实内核里 @{verbatim "ks_cur"} 会绕回（调度器轮转），
  但 @{verbatim "uwr"} 只比较 @{verbatim "ks_msgs"}，
  换谁执行不影响这里的证明，所以模型里省掉绕回。
\<close>

definition step_at :: "obj_ref \<Rightarrow> kstate \<Rightarrow> kstate" where
  "step_at k s \<equiv> s\<lparr> ks_msgs := (ks_msgs s)(k := ks_msgs s k + 1),
                   ks_cur := k + 1 \<rparr>"

definition step :: "kstate \<Rightarrow> kstate" where
  "step s \<equiv> step_at (ks_cur s) s"

text \<open>
  为什么要把"一步"写成 @{term "step_at k"}（显式给出线程 k）而不是
  @{term "step"}（自己取 @{term "ks_cur s"}）？因为非干扰比的是
  \emph{两个不同的世界}：一个喂了高输入，一个没喂。要比较两个世界
  就必须要求"这一步在两边是同一个线程跑的"，所以把线程号提到参数里，
  比事后用一条 @{term "ks_cur t = ks_cur s"} 的等式去对齐要干净得多。
  真实证明 @{verbatim "confidentiality_u"} 里也有同样一层
  "两个世界的调度必须一致"的条件。
\<close>

lemma low_step_preserves_uwr:
  assumes low: "level_of k = Low"
      and u:   "uwr s d t"
  shows "uwr (step_at k s) d (step_at k t)"
proof -
  text \<open>先把"擦除后一致"拆成逐对象的一致：凡不是高安全级的对象，两边本来相等。\<close>
  have base: "\<forall>p. level_of p \<noteq> High \<longrightarrow> ks_msgs s p = ks_msgs t p"
  proof (intro allI impI)
    fix p
    assume hp: "level_of p \<noteq> High"
    have fe: "ks_msgs (erase_high s) = ks_msgs (erase_high t)"
      using u by (simp add: uwr_def)
    then have h: "ks_msgs (erase_high s) p = ks_msgs (erase_high t) p"
      by (simp add: fun_eq_iff)
    then show "ks_msgs s p = ks_msgs t p"
      using hp by (simp add: erase_high_def)
  qed
  show ?thesis
    unfolding uwr_def step_at_def erase_high_def
    apply (rule ext)
    apply (rename_tac p)
    apply (case_tac "level_of p = High")
     apply simp
    apply (case_tac "p = k")
     apply simp
     apply (rule base[rule_format])
     apply (simp add: low)
    apply simp
    apply (rule base[rule_format])
    apply assumption
    done
qed

text \<open>
  注意这条引理的\emph{前提}：当前执行的线程必须是低安全级的。
  高安全级的线程运行时当然会改动高安全级的数据——
  那不是泄漏，只要低观察者擦除之后仍然看不出差别就行。
  真实证明里这叫 @{verbatim "confidentiality_u"} 一类定理，
  前提形如 @{verbatim "pasSubject aag \<notin> subjects ..."}。
\<close>

lemma high_step_may_change_high_data:
  "level_of (ks_cur s) = High \<Longrightarrow>
   ks_msgs (step s) (ks_cur s) = ks_msgs s (ks_cur s) + 1"
  by (simp add: step_def step_at_def)

subsection \<open>22.5 归纳到任意长的运行\<close>

fun run :: "nat \<Rightarrow> kstate \<Rightarrow> kstate" where
  "run 0 s = s"
| "run (Suc n) s = run n (step s)"

lemma run_zero: "run 0 s = s"
  by simp

lemma run_step_commutes: "run (Suc n) s = run n (step s)"
  by simp

lemma noninterference_for_runs:
  "(\<forall>s t. uwr s d t \<longrightarrow> uwr (step s) d (step t)) \<Longrightarrow>
   uwr s d t \<Longrightarrow> uwr (run n s) d (run n t)"
proof (induction n arbitrary: s t)
  case 0
  then show ?case by simp
next
  case (Suc n s t)
  have step_u: "uwr (step s) d (step t)"
    using Suc.prems by blast
  text \<open>把归纳假设用在"已经走了一步"的那对状态上。\<close>
  from Suc.IH[OF Suc.prems(1) step_u] show ?case by simp
qed

text \<open>
  @{thm noninterference_for_runs} 就是整章的主定理形状：
  \emph{单步保持不可区分} ⟹ \emph{任意步保持不可区分}。
  @{verbatim "Noninterference.thy"} 里真正的定理还要处理
  调度器选择、中断、以及"哪些步骤根本不允许发生"（由策略
  @{verbatim "pas"} 决定），但骨架就是这条归纳。
\<close>

ML \<open>
  writeln (@{make_string} @{thm uwr_transitive});
  writeln (@{make_string} @{thm noninterference_for_runs})
\<close>

ML \<open>writeln "==== 22 结束 ===="\<close>

end
