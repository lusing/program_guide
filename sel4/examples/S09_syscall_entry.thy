theory S09_syscall_entry
  imports Main
begin

section \<open>9.1 内核只有一个入口\<close>

text \<open>
  seL4 从用户态进入内核只有一条路：陷阱。进内核之后第一件事是判断
  "这次是什么事"，由 @{verbatim "l4v/spec/abstract/Syscall_A.thy"} 第 376 行的
  @{verbatim "call_kernel"} 分发到 @{verbatim "handle_event"}（第 325 行）：

  @{verbatim "call_kernel ev \<equiv> do handle_event ev <handle> (\<lambda>_. without_preemption $ maybe_handle_interrupt True); schedule; activate_thread od"}

  @{verbatim "handle_event"} 是一次对 @{verbatim "event"} 的完整分案。真实
  @{verbatim "event"} 有六个构造子，写在
  @{verbatim "l4v/spec/haskell/src/SEL4/API/Syscall.lhs"} 第 43 行
  （Isabelle 侧的 @{verbatim "Event_H"} 由它生成，不在仓库里）：
  @{verbatim "SyscallEvent"}、@{verbatim "UnknownSyscall"}、
  @{verbatim "UserLevelFault"}、@{verbatim "Interrupt"}、
  @{verbatim "VMFaultEvent"}、@{verbatim "HypervisorEvent"}。
  注意 @{verbatim "Interrupt"} \emph{不带参数}——中断号在内核里已经被
  翻译成具体的 handler 能力了。
\<close>

ML \<open>writeln "==== 09 开始 ===="\<close>

text \<open>
  系统调用那一支的参数是 @{verbatim "Syscall"}（同一文件第 58 行）。
  master API 一共八个，与 @{verbatim "seL4/libsel4/include/api/syscall.xml"}
  的 @{verbatim "<api-master>"} 一节逐字对应：
\<close>

datatype syscall = SysCall | SysReplyRecv | SysSend | SysNBSend | SysRecv
                   | SysReply | SysYield | SysNBRecv

text \<open>
  MCS（@{verbatim "CONFIG_KERNEL_MCS"}）另外加 @{verbatim "NBSendRecv"}、
  @{verbatim "NBSendWait"}、@{verbatim "Wait"}、@{verbatim "NBWait"}，
  并去掉 @{verbatim "Reply"}。L4V 的抽象规范按 master API 建模。
  \emph{没有} @{verbatim "Poll"} 这个系统调用——别按其它微内核的习惯猜。
\<close>

datatype lookup_failure = InvalidRoot | MissingCapability nat
                        | DepthMismatch nat nat | GuardMismatch nat "bool list"

text \<open>
  @{verbatim "lookup_failure"} 与 @{verbatim "fault"} 都是
  @{verbatim "l4v/spec/abstract/ExceptionTypes_A.thy"} 里真实的类型
  （第 28 行与第 34 行）。这里把 @{verbatim "obj_ref"} 与
  @{verbatim "machine_word"} 换成了 @{verbatim "nat"}，构造子与字段个数保持一致：
\<close>

datatype fault = CapFault nat bool lookup_failure
               | UnknownSyscallException nat
               | UserException nat nat
               | ArchFault nat

text \<open>
  第四个构造子 @{verbatim "ArchFault"} 也来自同一条定义；VM fault 在真实规范里
  正是挂在它下面（@{verbatim "l4v/spec/abstract/ARM/Machine_A.thy"} 第 163 行：
  @{verbatim "arch_fault = VMFault vspace_ref machine_word list"}）。
\<close>

datatype event = SyscallEvent syscall | UnknownSyscall nat
               | UserLevelFault nat nat | Interrupt | VMFaultEvent nat

subsection \<open>9.2 三段式：fault / error / finalise\<close>

text \<open>
  @{verbatim "Syscall_A.thy"} 第 85 行的 @{verbatim "syscall"} 组合子是本章主角。
  它的本体（第 85--101 行）依次做五件事：
  先 @{verbatim "r_fault \<leftarrow> without_preemption $ m_fault"}，
  然后 @{verbatim "case r_fault of Inl f \<Rightarrow> without_preemption $ h_fault f"}；
  没有故障时才走第二段 @{verbatim "r_error \<leftarrow> without_preemption $ m_error a"}，
  同样 @{verbatim "Inl e \<Rightarrow> without_preemption $ h_error e"}；
  两段都过了才执行 @{verbatim "m_finalise b"}。

  三点要看准：第一，故障与错误都用 @{verbatim "sum"} 表示（@{verbatim "Inl"} 是失败），
  不是 option；第二，@{verbatim "m_error"} 是\emph{依赖于}第一段结果的函数
  @{verbatim "m_error a"}；第三，四段全被 @{verbatim "without_preemption"}
  包着，\emph{只有} @{verbatim "m_finalise b"} 没有——可抢占的只有提交那一步。
\<close>

definition syscall3 ::
  "(fault + 'a) \<Rightarrow> (fault \<Rightarrow> 'r) \<Rightarrow> ('a \<Rightarrow> (nat + 'b)) \<Rightarrow> (nat \<Rightarrow> 'r)
   \<Rightarrow> ('b \<Rightarrow> 'r) \<Rightarrow> 'r" where
  "syscall3 mf hf me he mf2 \<equiv> case mf of
      Inl f \<Rightarrow> hf f
    | Inr a \<Rightarrow> (case me a of
          Inl e \<Rightarrow> he e
        | Inr b \<Rightarrow> mf2 b)"

lemma fault_wins:
  "syscall3 (Inl f) hf me he mf2 = hf f"
  by (simp add: syscall3_def)

lemma fault_shadows_error:
  "syscall3 (Inl f) hf me he mf2 = syscall3 (Inl f) hf me' he mf2"
  by (simp add: syscall3_def)

lemma error_when_no_fault:
  "syscall3 (Inr a) hf me he mf2 = (case me a of Inl e \<Rightarrow> he e | Inr b \<Rightarrow> mf2 b)"
  by (simp add: syscall3_def)

lemma finalise_when_all_ok:
  "me a = Inr b \<Longrightarrow> syscall3 (Inr a) hf me he mf2 = mf2 b"
  by (simp add: syscall3_def)

text \<open>
  @{thm fault_shadows_error} 说明的是\emph{优先级}：故障比错误先被处理，
  而且第二段的 @{verbatim "m_error"} 根本不会被调用。真实内核里这决定了
  用户最终看到的是 fault 消息还是错误码——顺序写错，ABI 就错了。
\<close>

subsection \<open>9.3 handle_invocation：三段怎么被两个布尔开关拧起来\<close>

text \<open>
  @{verbatim "Syscall_A.thy"} 第 213 行的
  @{verbatim "handle_invocation :: bool \<Rightarrow> bool \<Rightarrow> _ p_monad"} 是
  @{verbatim "syscall"} 组合子的实例，两个参数依次是
  @{verbatim "calling"} 与 @{verbatim "blocking"}：

  \begin{itemize}
    \item 第一段：@{verbatim "cap_fault_on_failure (of_bl ptr) False $ lookup_cap_and_slot thread ptr"}，
          再 @{verbatim "lookup_ipc_buffer"} 与 @{verbatim "lookup_extra_caps"}；
    \item 故障处理：@{verbatim "(\<lambda>fault. when blocking $ handle_fault thread fault)"}；
    \item 第二段：@{verbatim "decode_invocation (mi_label info) args ptr slot cap extracaps"}；
    \item 错误处理：@{verbatim "(\<lambda>err. when calling $ reply_from_kernel thread $ msg_from_syscall_error err)"}；
    \item 第三段：@{verbatim "perform_invocation blocking calling oper"}（第 154 行）。
  \end{itemize}

  两个 @{verbatim "when"} 是关键：\emph{同一个失败，不同系统调用报给用户的东西不一样}。
  另外注意最后一步的参数顺序翻了——@{verbatim "handle_invocation calling blocking"}
  调的是 @{verbatim "perform_invocation blocking calling"}。
\<close>

text \<open>
  @{verbatim "invocation"} 在真实规范里是
  @{verbatim "l4v/spec/abstract/Invocations_A.thy"} 第 69 行的十个构造子
  （@{verbatim "InvokeUntyped"}、@{verbatim "InvokeEndpoint"}、
  @{verbatim "InvokeNotification"}、@{verbatim "InvokeReply"}、
  @{verbatim "InvokeTCB"}、@{verbatim "InvokeDomain"}、@{verbatim "InvokeCNode"}、
  @{verbatim "InvokeIRQControl"}、@{verbatim "InvokeIRQHandler"}、
  @{verbatim "InvokeArchObject"}）。这里只留三个够用的：
\<close>

datatype invocation = InvokeEndpoint nat | InvokeCNodeOp nat | InvokeTCBOp nat

datatype observed = SawFault | SawError | Performed | Silent

definition handle_invocation ::
  "bool \<Rightarrow> bool \<Rightarrow> (fault + unit) \<Rightarrow> (unit \<Rightarrow> (nat + invocation)) \<Rightarrow> observed" where
  "handle_invocation calling blocking r_fault r_error \<equiv>
     syscall3 r_fault (\<lambda>f. if blocking then SawFault else Silent)
              r_error (\<lambda>e. if calling then SawError else Silent)
              (\<lambda>b. Performed)"


lemma fault_reported_only_when_blocking:
  "handle_invocation calling True (Inl f) r_error = SawFault"
  by (simp add: handle_invocation_def syscall3_def)

lemma fault_swallowed_when_nonblocking:
  "handle_invocation calling False (Inl f) r_error = Silent"
  by (simp add: handle_invocation_def syscall3_def)

lemma error_reported_only_when_calling:
  "r_error a = Inl e \<Longrightarrow> handle_invocation True blocking (Inr a) r_error = SawError"
  by (simp add: handle_invocation_def syscall3_def)

lemma error_swallowed_when_not_calling:
  "r_error a = Inl e \<Longrightarrow> handle_invocation False blocking (Inr a) r_error = Silent"
  by (simp add: handle_invocation_def syscall3_def)

lemma ok_reaches_finalise:
  "r_error a = Inr b \<Longrightarrow> handle_invocation calling blocking (Inr a) r_error = Performed"
  by (simp add: handle_invocation_def syscall3_def)

text \<open>
  三条合起来解释了一个真实现象：@{verbatim "seL4_Send"} 出错时用户寄存器里
  看不到错误码，只有 @{verbatim "seL4_Call"} 才有返回值的 ABI 约定——
  这道闸在规范里就是那个 @{verbatim "calling"} 开关（@{verbatim "l4v/spec/abstract/Syscall_A.thy"} 第 233 行）。
  模型的 @{verbatim "Silent"} 就是"这一支什么都不回"。
\<close>

subsection \<open>9.4 事件分发：中断不该碰到 CSpace\<close>

text \<open>
  @{verbatim "handle_event"}（第 325--339 行）对系统调用的分案是逐条写死的：

  八支是逐条写死的（第 327--339 行）：@{verbatim "SysSend"} 走
  @{verbatim "handle_send True"}、@{verbatim "SysNBSend"} 走
  @{verbatim "handle_send False"}、@{verbatim "SysCall"} 走 @{verbatim "handle_call"}；
  剩下五支走各自的处理器——@{verbatim "SysRecv"} 与 @{verbatim "SysNBRecv"} 进
  @{verbatim "handle_recv True/False"}，@{verbatim "SysYield"} 进
  @{verbatim "handle_yield"}，@{verbatim "SysReply"} 进 @{verbatim "handle_reply"}，
  @{verbatim "SysReplyRecv"} 则是 @{verbatim "handle_reply"} 之后接
  @{verbatim "handle_recv True"}。后五支全部被 @{verbatim "without_preemption"} 包着。

  配上第 262--267 行的 @{verbatim "handle_send bl \<equiv> handle_invocation False bl"}
  与 @{verbatim "handle_call \<equiv> handle_invocation True True"}，
  "谁能进入能力调用路径"就有了精确答案——\emph{三个}，不是两个。
\<close>

definition is_invocation :: "syscall \<Rightarrow> bool" where
  "is_invocation s \<equiv> s = SysSend \<or> s = SysNBSend \<or> s = SysCall"

lemma only_three_syscalls_invoke:
  "is_invocation s \<Longrightarrow> s = SysSend \<or> s = SysNBSend \<or> s = SysCall"
  by (simp add: is_invocation_def)

lemma nbsend_is_an_invocation: "is_invocation SysNBSend"
  by (simp add: is_invocation_def)

lemma recv_is_not_invocation: "\<not> is_invocation SysRecv"
  by (simp add: is_invocation_def)

datatype action = DoInvocation syscall | DoFault fault | DoInterrupt | DoOther syscall

definition handle_event :: "event \<Rightarrow> action" where
  "handle_event e \<equiv> case e of
      SyscallEvent s \<Rightarrow> if is_invocation s then DoInvocation s else DoOther s
    | UnknownSyscall n \<Rightarrow> DoFault (UnknownSyscallException n)
    | UserLevelFault w1 w2 \<Rightarrow> DoFault (UserException w1 w2)
    | Interrupt         \<Rightarrow> DoInterrupt
    | VMFaultEvent t    \<Rightarrow> DoFault (ArchFault t)"

definition touches_cspace :: "action \<Rightarrow> bool" where
  "touches_cspace a \<equiv> case a of DoInvocation _ \<Rightarrow> True | _ \<Rightarrow> False"

lemma interrupt_never_touches_cspace:
  "\<not> touches_cspace (handle_event Interrupt)"
  by (simp add: handle_event_def touches_cspace_def)

lemma yield_does_not_invoke:
  "handle_event (SyscallEvent SysYield) = DoOther SysYield"
  by (simp add: handle_event_def is_invocation_def)

lemma send_invokes:
  "handle_event (SyscallEvent SysSend) = DoInvocation SysSend"
  by (simp add: handle_event_def is_invocation_def)

lemma nbsend_invokes:
  "handle_event (SyscallEvent SysNBSend) = DoInvocation SysNBSend"
  by (simp add: handle_event_def is_invocation_def)

lemma non_invocation_syscalls_never_touch_cspace:
  "\<not> is_invocation s \<Longrightarrow> \<not> touches_cspace (handle_event (SyscallEvent s))"
  by (cases s) (auto simp: handle_event_def touches_cspace_def is_invocation_def)

text \<open>
  最后这条是本章真正想要的形状：\emph{八个系统调用里只有三个进 CSpace}。
  它在证明里不是显然的——@{verbatim "Interrupt_A.thy"} 的中断处理与
  @{verbatim "handle_invocation"} 属于不同的 development，
  必须把两边的作用域分开才能证。
\<close>

ML \<open>
  writeln (@{make_string} @{thm fault_swallowed_when_nonblocking});
  writeln (@{make_string} @{thm non_invocation_syscalls_never_touch_cspace})
\<close>

ML \<open>writeln "==== 09 结束 ===="\<close>

end
