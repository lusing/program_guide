theory S13_tcb
  imports Main
begin

section \<open>13.1 TCB：内核眼里的"线程"\<close>

text \<open>
  线程控制块（TCB）在 @{verbatim "l4v/spec/abstract/Structures_A.thy"}
  第 388 行是一条 @{verbatim "record"}，前五个字段\emph{全是能力}：
  @{verbatim "tcb_ctable"}（CSpace 根）、@{verbatim "tcb_vtable"}（VSpace 根）、
  @{verbatim "tcb_reply"}、@{verbatim "tcb_caller"}、@{verbatim "tcb_ipcframe"}，
  之后才是 @{verbatim "tcb_state"}、@{verbatim "tcb_fault_handler"}、
  @{verbatim "tcb_ipc_buffer"}、@{verbatim "tcb_fault"}、
  @{verbatim "tcb_bound_notification"}、@{verbatim "tcb_mcpriority"}、
  @{verbatim "tcb_priority"} 等。

  也就是说：TCB 本身就是 CSpace 里的一类对象，
  @{verbatim "CSpaceAcc_A.thy"} 第 44 行的 @{verbatim "set_cap"} 有专门一支处理它。
\<close>

ML \<open>writeln "==== 13 开始 ===="\<close>

type_synonym obj_ref = nat

datatype cap = NullCap | CNodeCap obj_ref | ThreadCap obj_ref
             | EndpointCap obj_ref | IpcBufferCap obj_ref

subsection \<open>13.2 线程状态：八个构造子，两个带载荷\<close>

text \<open>
  @{verbatim "Structures_A.thy"} 第 362--370 行的 @{verbatim "thread_state"}
  是八个构造子。注意 @{verbatim "BlockedOnReceive"} 与
  @{verbatim "BlockedOnSend"} 各带\emph{两个}参数：端点引用，加上
  @{verbatim "receiver_payload"} / @{verbatim "sender_payload"}——
  线程睡着的时候，"当时正在跟谁说话"这件事必须留在状态里，
  否则取消 IPC（第 11 章的 @{verbatim "cancel_ipc"}）就找不到该通知谁。
\<close>

datatype payload = NoPayload | Payload nat

datatype thread_state =
    Running
  | Inactive
  | Restart
  | BlockedOnReceive obj_ref payload
  | BlockedOnSend obj_ref payload
  | BlockedOnReply
  | BlockedOnNotification obj_ref
  | IdleThreadState

subsection \<open>13.3 可运行性：只有两个状态算"能上 CPU"\<close>

text \<open>
  真实定义 @{verbatim "Structures_A.thy"} 第 409 行的 @{verbatim "runnable"}
  是一条 @{verbatim "primrec"}，八个状态逐个列：@{verbatim "Running"} 与
  @{verbatim "Restart"} 为真，其余六个为假。模型照抄这张表。
\<close>

primrec runnable :: "thread_state \<Rightarrow> bool" where
  "runnable (Running)                     = True"
| "runnable (Inactive)                    = False"
| "runnable (Restart)                     = True"
| "runnable (BlockedOnReceive e p)        = False"
| "runnable (BlockedOnSend e p)           = False"
| "runnable (BlockedOnReply)              = False"
| "runnable (BlockedOnNotification e)     = False"
| "runnable (IdleThreadState)             = False"

lemma running_is_runnable: "runnable Running"
  by simp

lemma restart_is_runnable: "runnable Restart"
  by simp

lemma inactive_is_not_runnable: "\<not> runnable Inactive"
  by simp

lemma blocked_is_not_runnable:
  "\<not> runnable (BlockedOnSend p x) \<and> \<not> runnable (BlockedOnReceive p x)
   \<and> \<not> runnable BlockedOnReply \<and> \<not> runnable (BlockedOnNotification p)"
  by simp

lemma idle_is_not_runnable: "\<not> runnable IdleThreadState"
  by simp

text \<open>
  @{thm inactive_is_not_runnable} 值得单独一条：@{verbatim "Inactive"}
  \emph{不}可运行，那是"被挂起、等人唤醒"的线程；
  @{verbatim "IdleThreadState"} 也不可运行，它是每个域里那个
  "没事干时跑的空转线程"。两个"停着"的状态在调度里的待遇不同
  （第 14 章）。
\<close>

subsection \<open>13.4 TCB 记录与 @{verbatim "thread_set"}\<close>

text \<open>
  内核里所有对 TCB 的修改都经由 @{verbatim "KHeap_A.thy"} 第 63 行的
  @{verbatim "thread_set"}：它取一个 @{verbatim "tcb \<Rightarrow> tcb"} 这样的
  \emph{函数}作为参数。文件后面那批 @{verbatim "thread_set_priority"}
  （第 247 行）、@{verbatim "thread_set_time_slice"}（第 251 行）
  全都是在它上面套一个 record 更新。模型保留"更新函数"这个形状。
\<close>

record tcb =
  tcb_ctable     :: cap
  tcb_vtable     :: cap
  tcb_reply      :: cap
  tcb_caller     :: cap
  tcb_ipcframe   :: cap
  tcb_state      :: thread_state
  tcb_priority   :: nat
  tcb_mcpriority :: nat
  tcb_ipc_buffer :: obj_ref

definition default_tcb :: tcb where
  "default_tcb \<equiv> \<lparr> tcb_ctable = NullCap, tcb_vtable = NullCap,
                      tcb_reply = NullCap, tcb_caller = NullCap,
                      tcb_ipcframe = NullCap, tcb_state = Inactive,
                      tcb_priority = 0, tcb_mcpriority = 0,
                      tcb_ipc_buffer = 0 \<rparr>"

definition thread_set :: "(tcb \<Rightarrow> tcb) \<Rightarrow> tcb \<Rightarrow> tcb" where
  "thread_set f t \<equiv> f t"

definition set_thread_state :: "thread_state \<Rightarrow> tcb \<Rightarrow> tcb" where
  "set_thread_state ts \<equiv> (\<lambda>t. t\<lparr> tcb_state := ts \<rparr>)"

definition set_priority :: "nat \<Rightarrow> tcb \<Rightarrow> tcb" where
  "set_priority p \<equiv> (\<lambda>t. t\<lparr> tcb_priority := p \<rparr>)"

lemma set_state_changes_only_state:
  "tcb_state (thread_set (set_thread_state ts) t) = ts"
  "tcb_priority (thread_set (set_thread_state ts) t) = tcb_priority t"
  "tcb_ctable (thread_set (set_thread_state ts) t) = tcb_ctable t"
  by (auto simp: thread_set_def set_thread_state_def)

lemma set_priority_changes_only_priority:
  "tcb_priority (thread_set (set_priority p) t) = p"
  "tcb_state (thread_set (set_priority p) t) = tcb_state t"
  by (auto simp: thread_set_def set_priority_def)

lemma thread_set_composes:
  "thread_set f (thread_set g t) = thread_set (f \<circ> g) t"
  by (simp add: thread_set_def)

text \<open>
  这类"只动一个字段"的引理在真实证明里成百上千条地存在
  （@{verbatim "TcbAcc_A.thy"} 就专门负责读写 TCB 字段），
  它们不是装饰：每一次 @{verbatim "thread_set"} 之后，
  不变式证明都要靠它们说明"别的字段没变"。
\<close>

subsection \<open>13.5 挂起与唤醒：两个都有前提\<close>

text \<open>
  真实 @{verbatim "suspend"}（@{verbatim "l4v/spec/abstract/IpcCancel_A.thy"}
  第 368 行）做四件事：先 @{verbatim "cancel_ipc"}、正在 Running 才
  @{verbatim "update_restart_pc"}、然后 @{verbatim "tcb_sched_dequeue"}、
  最后置 @{verbatim "Inactive"}。

  "唤醒"那一半在规范里不叫 @{verbatim "resume"}，叫
  @{verbatim "restart"}（@{verbatim "Tcb_A.thy"} 第 42 行），
  而且整条被 @{verbatim "when (\<not> runnable state \<and> \<not> idle state)"} 包着——
  \emph{对一个正在运行的线程调用 restart 是什么都不做的}。
  用户看到的 @{verbatim "seL4_TCB_Resume"} 走的正是这条路。
\<close>

text \<open>
  规范里 @{verbatim "restart"} 的前提用到另一个谓词 @{verbatim "idle"}。
  模型把它列成与 @{verbatim "runnable"} 对称的一张表——
  两个谓词合起来恰好把八个状态分成三类：能上 CPU、睡着、空转。
\<close>

primrec idle_state :: "thread_state \<Rightarrow> bool" where
  "idle_state (Running)                 = False"
| "idle_state (Inactive)                 = False"
| "idle_state (Restart)                  = False"
| "idle_state (BlockedOnReceive e p)     = False"
| "idle_state (BlockedOnSend e p)         = False"
| "idle_state (BlockedOnReply)            = False"
| "idle_state (BlockedOnNotification e)   = False"
| "idle_state (IdleThreadState)           = True"

lemma idle_state_is_idle_thread: "idle_state ts = (ts = IdleThreadState)"
  by (cases ts) auto

lemma only_eight_states:
  "\<not> runnable Inactive \<and> \<not> idle_state Inactive"
  by simp

definition suspend :: "tcb \<Rightarrow> tcb" where
  "suspend t \<equiv> (t\<lparr> tcb_state := Inactive \<rparr>)"

definition restart :: "tcb \<Rightarrow> tcb" where
  "restart t \<equiv>
     if runnable (tcb_state t) \<or> idle_state (tcb_state t) then t
     else t\<lparr> tcb_state := Restart \<rparr>"

lemma suspend_makes_inactive: "tcb_state (suspend t) = Inactive"
  by (simp add: suspend_def)

lemma suspend_is_not_runnable: "\<not> runnable (tcb_state (suspend t))"
  by (simp add: suspend_def)

lemma restart_makes_runnable:
  "\<not> idle_state (tcb_state t) \<Longrightarrow> runnable (tcb_state (restart t))"
  by (auto simp: restart_def split: thread_state.splits)

lemma restart_on_running_is_noop:
  "runnable (tcb_state t) \<Longrightarrow> restart t = t"
  by (auto simp: restart_def split: thread_state.splits)

lemma restart_on_idle_is_noop:
  "idle_state (tcb_state t) \<Longrightarrow> restart t = t"
  by (auto simp: restart_def split: thread_state.splits)

lemma restart_on_blocked_sets_restart_state:
  "tcb_state t = BlockedOnReply \<Longrightarrow> tcb_state (restart t) = Restart"
  by (simp add: restart_def)

lemma suspend_then_restart_state:
  "tcb_state (restart (suspend t)) = Restart"
  by (simp add: suspend_def restart_def)

text \<open>
  @{thm restart_on_running_is_noop} 是本章最容易被忽视的一条：
  "恢复一个本来就在跑的线程"必须是空操作，否则任何线程都能被
  强行打断。反过来 @{thm suspend_then_restart_state} 说明
  suspend/restart 这对操作在状态层面是"可恢复"的——
  真正的坑是调度队列：@{verbatim "suspend"} 里那句
  @{verbatim "tcb_sched_dequeue"} 与 @{verbatim "restart"} 里的
  @{verbatim "tcb_sched_enqueue"} 必须配对，
  顺序错了就会出现"不在队列里却可运行"的幽灵线程。
  第 17 章的不变式就是用来排除它的。
\<close>

subsection \<open>13.6 TCB 只有五个能力槽\<close>

text \<open>
  @{verbatim "tcb_cnode_index"} 的定义在
  @{verbatim "l4v/spec/abstract/Structures_A.thy"} 第 615 行：
  @{verbatim "tcb_cnode_index n \<equiv> to_bl (of_nat n :: 3 word)"}——
  它是一个\emph{三位}向量的位列表。使用它的是
  @{verbatim "CSpaceAcc_A.thy"} 第 53--61 行那一串
  @{verbatim "if cref = tcb_cnode_index 0 then … tcb_ctable …"}：
  只有 0--4 这五个索引有分支，\emph{第六个就 @{verbatim "fail"}}。
  模型把"索引→字段"写成显式的偏函数，好让这条边界可证。
\<close>

definition update_tcb_slot :: "cap \<Rightarrow> nat \<Rightarrow> tcb \<Rightarrow> tcb option" where
  "update_tcb_slot cap n t \<equiv>
     if n = 0 then Some (t\<lparr> tcb_ctable := cap \<rparr>)
     else if n = 1 then Some (t\<lparr> tcb_vtable := cap \<rparr>)
     else if n = 2 then Some (t\<lparr> tcb_reply := cap \<rparr>)
     else if n = 3 then Some (t\<lparr> tcb_caller := cap \<rparr>)
     else if n = 4 then Some (t\<lparr> tcb_ipcframe := cap \<rparr>)
     else None"

lemma slot_zero_is_ctable:
  "update_tcb_slot c 0 t = Some (t\<lparr> tcb_ctable := c \<rparr>)"
  by (simp add: update_tcb_slot_def)

lemma slot_four_is_ipcframe:
  "update_tcb_slot c 4 t = Some (t\<lparr> tcb_ipcframe := c \<rparr>)"
  by (simp add: update_tcb_slot_def)

lemma slot_five_is_rejected: "update_tcb_slot c 5 t = None"
  by (simp add: update_tcb_slot_def)

lemma only_five_slots: "n \<ge> 5 \<Longrightarrow> update_tcb_slot c n t = None"
  by (auto simp: update_tcb_slot_def split: if_splits)

lemma accepted_slot_never_touches_state:
  "update_tcb_slot c n t = Some t' \<Longrightarrow> n < 5 \<and> tcb_state t' = tcb_state t"
  by (auto simp: update_tcb_slot_def split: if_splits)

text \<open>
  换个说法：TCB 是一个\emph{定长五个槽}的 CNode，槽号 5 起一律失败。
  线程的能力查找起点永远是 0 号槽（@{verbatim "tcb_ctable"}）。
  这五个槽不是摆设，两个例子：
  @{verbatim "setup_reply_master"}（@{verbatim "l4v/spec/abstract/Tcb_A.thy"}
  第 30 行）只在 2 号槽为 @{verbatim "NullCap"} 时才写入
  一条 master reply 能力（@{verbatim "ReplyCap thread True"}，
  权利是 AllowGrant 与 AllowWrite）——
  每个活跃线程都有一份\emph{主} reply 能力；
  而 @{verbatim "setup_caller_cap"}（@{verbatim "l4v/spec/abstract/Ipc_A.thy"}
  第 289--290 行）用 @{verbatim "cap_insert"}
  （@{verbatim "CSpace_A.thy"} 第 762 行）把
  @{verbatim "ReplyCap sender False"}（权利里必带 @{verbatim "AllowWrite"}，
  可能还带 @{verbatim "AllowGrant"}）插进\emph{接收者}的 3 号槽，
  源槽正是发送者的 2 号槽。第 12 章"reply 不可复制"说的是用户态，
  内核在 Call 的那一刻自己派生这份非主副本。
\<close>

ML \<open>
  writeln (@{make_string} @{thm restart_on_running_is_noop});
  writeln (@{make_string} @{thm only_five_slots})
\<close>

ML \<open>writeln "==== 13 结束 ===="\<close>

end
