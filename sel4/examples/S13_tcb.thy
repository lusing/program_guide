theory S13_tcb
  imports Main
begin

section \<open>13.1 TCB：内核眼里的"线程"\<close>

text \<open>
  线程控制块（TCB）在 @{verbatim "l4v/spec/abstract/Structures_A.thy"}
  第 388 行是一个 @{verbatim "record"}，前面几个字段全是能力：

  @{verbatim "tcb_ctable"}（CSpace 根）、@{verbatim "tcb_vtable"}（VSpace 根）、
  @{verbatim "tcb_reply"}、@{verbatim "tcb_caller"}、@{verbatim "tcb_ipcframe"}，
  然后是 @{verbatim "tcb_state"}、@{verbatim "tcb_fault_handler"}、
  @{verbatim "tcb_ipc_buffer"}、@{verbatim "tcb_fault"}、
  @{verbatim "tcb_bound_notification"}、优先级等等。

  注意前五个槽位：CNode 里存的是"能力表"，而 TCB 里这五个位置
  本身就是能力槽（@{verbatim "CSpaceAcc_A.thy"} 第 44 行的
  @{verbatim "set_cap"} 对 @{verbatim "TCB"} 分支就专门处理它们）。
\<close>

ML \<open>writeln "==== 13 开始 ===="\<close>

type_synonym obj_ref = nat
type_synonym priority = nat

datatype cap = NullCap | CNodeCap obj_ref | ThreadCap obj_ref | EndpointCap obj_ref

datatype thread_state =
    Running
  | Inactive
  | Restart
  | BlockedOnReceive obj_ref
  | BlockedOnSend obj_ref
  | BlockedOnReply
  | BlockedOnNotification obj_ref
  | IdleThreadState

record tcb =
  tcb_ctable    :: cap
  tcb_vtable    :: cap
  tcb_reply     :: cap
  tcb_state     :: thread_state
  tcb_priority  :: priority
  tcb_ipc_buffer :: obj_ref

definition default_tcb :: tcb where
  "default_tcb \<equiv> \<lparr> tcb_ctable = NullCap, tcb_vtable = NullCap, tcb_reply = NullCap,
                   tcb_state = Inactive, tcb_priority = 0, tcb_ipc_buffer = 0 \<rparr>"

subsection \<open>13.2 可运行性\<close>

definition runnable :: "thread_state \<Rightarrow> bool" where
  "runnable ts \<equiv> ts = Running \<or> ts = Restart"

lemma running_is_runnable: "runnable Running"
  by (simp add: runnable_def)

lemma blocked_on_send_is_not_runnable: "\<not> runnable (BlockedOnSend p)"
  by (simp add: runnable_def)

lemma idle_is_not_runnable: "\<not> runnable IdleThreadState"
  by (simp add: runnable_def)

text \<open>
  真实定义 @{verbatim "Structures_A.thy"} 第 409 行的 @{verbatim "runnable"}
  只认 @{verbatim "Running"} 与 @{verbatim "Restart"}。注意
  @{verbatim "Inactive"} \emph{不}可运行：那是"还没有被启动"的线程。
\<close>

subsection \<open>13.3 改一个字段，别的字段不动\<close>

text \<open>
  内核里所有对 TCB 的修改都走 @{verbatim "thread_set"}
  （@{verbatim "Tcb_A.thy"}）。模型用 record 更新表达同一件事，
  并证明"只动了想动的那个字段"。
\<close>

definition set_thread_state :: "thread_state \<Rightarrow> tcb \<Rightarrow> tcb" where
  "set_thread_state ts t \<equiv> t\<lparr> tcb_state := ts \<rparr>"

definition set_priority :: "priority \<Rightarrow> tcb \<Rightarrow> tcb" where
  "set_priority p t \<equiv> t\<lparr> tcb_priority := p \<rparr>"

lemma set_state_changes_only_state:
  "tcb_state (set_thread_state ts t) = ts"
  "tcb_priority (set_thread_state ts t) = tcb_priority t"
  "tcb_ctable (set_thread_state ts t) = tcb_ctable t"
  by (auto simp: set_thread_state_def)

lemma set_priority_changes_only_priority:
  "tcb_priority (set_priority p t) = p"
  "tcb_state (set_priority p t) = tcb_state t"
  by (auto simp: set_priority_def)

lemma set_state_idempotent:
  "set_thread_state ts (set_thread_state ts t) = set_thread_state ts t"
  by (auto simp: set_thread_state_def)

text \<open>
  这类"只动一个字段"的引理在真实证明里是成百上千条地存在的
  （@{verbatim "NonDetMonadLemmaBucket.thy"}、@{verbatim "TcbAcc_A.thy"}），
  它们不是装饰：每一次 @{verbatim "thread_set"} 之后，不变式证明都要
  靠它们说明"别的字段没变"。
\<close>

subsection \<open>13.4 挂起与恢复\<close>

definition suspend :: "tcb \<Rightarrow> tcb" where
  "suspend t \<equiv> t\<lparr> tcb_state := Inactive \<rparr>"

definition resume :: "tcb \<Rightarrow> tcb" where
  "resume t \<equiv> t\<lparr> tcb_state := Restart \<rparr>"

lemma suspend_makes_inactive: "tcb_state (suspend t) = Inactive"
  by (simp add: suspend_def)

lemma resume_makes_runnable: "runnable (tcb_state (resume t))"
  by (simp add: resume_def runnable_def)

lemma suspend_then_resume_state:
  "tcb_state (resume (suspend t)) = Restart"
  by (simp add: suspend_def resume_def)

text \<open>
  真实内核的 @{verbatim "suspend"} 还要把线程从调度队列里摘掉
  （@{verbatim "Tcb_A.thy"} 第 269 行的 @{verbatim "tcb_sched_action tcb_sched_dequeue"}），
   @{verbatim "resume"} 再放回去。顺序错了就会出现"不在队列里却可运行"
   的幽灵线程——第 17 章的不变式就是用来排除它的。
\<close>

subsection \<open>13.5 TCB 里的 CSpace 根\<close>

definition tcb_cnode_index :: "nat \<Rightarrow> nat" where
  "tcb_cnode_index n \<equiv> n"

lemma ctable_is_slot_zero: "tcb_cnode_index 0 = 0"
  by (simp add: tcb_cnode_index_def)

text \<open>
  @{verbatim "CSpaceAcc_A.thy"} 第 44 行里 @{verbatim "tcb_cnode_index 0"} 到
  @{verbatim "4"} 分别对应 ctable / vtable / reply / caller / ipcframe。
  也就是说：TCB 本身是一个"有 5 个槽的 CNode"，而线程的能力查找
  起点永远是 0 号槽。
\<close>

ML \<open>
  writeln (@{make_string} @{thm set_state_idempotent});
  writeln (@{make_string} @{thm resume_makes_runnable})
\<close>

ML \<open>writeln "==== 13 结束 ===="\<close>

end
