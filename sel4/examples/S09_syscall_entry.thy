theory S09_syscall_entry
  imports Main
begin

section \<open>9.1 内核只有一个入口\<close>

text \<open>
  seL4 从用户态进入内核只有一条路：陷阱。进内核之后第一件事是判断
  "这次是什么事"，由 @{verbatim "l4v/spec/abstract/Syscall_A.thy"} 的
  @{verbatim "call_kernel"} 分发：

  \begin{itemize}
    \item 一次真正的系统调用（@{verbatim "SysSend"}、@{verbatim "SysCall"}、
          @{verbatim "SysRecv"}、@{verbatim "SysReply"}、@{verbatim "SysNBSend"}、
          @{verbatim "SysPoll"}、@{verbatim "SysYield"}）；
    \item 一次故障（cap fault、VM fault 等，见
          @{verbatim "seL4/src/api/faults.c"}）；
    \item 一次中断；
    \item 虚拟化相关的 VM fault / hypervisor fault。
  \end{itemize}

  只有 @{verbatim "SysSend"} 与 @{verbatim "SysCall"} 会走到"方法调用"
  （@{verbatim "handle_invocation"}），其余各走各的处理函数。
\<close>

ML \<open>writeln "==== 09 开始 ===="\<close>

datatype syscall = SysSend | SysCall | SysRecv | SysReply | SysNBSend | SysPoll | SysYield

datatype fault = CapFault | VMFault | DebugFault

datatype event = SyscallEvent syscall | FaultEvent fault | InterruptEvent nat

definition is_invocation :: "syscall \<Rightarrow> bool" where
  "is_invocation s \<equiv> s = SysSend \<or> s = SysCall"

lemma only_send_and_call_invoke:
  "is_invocation s \<Longrightarrow> s = SysSend \<or> s = SysCall"
  by (simp add: is_invocation_def)

lemma recv_is_not_invocation: "\<not> is_invocation SysRecv"
  by (simp add: is_invocation_def)

subsection \<open>9.2 三段式：fault / error / finalise\<close>

text \<open>
  @{verbatim "Syscall_A.thy"} 里最关键的设计是这个通用组合子（见该文件
  "Generic system call structure" 一节）：系统调用被切成三段，
  \begin{itemize}
    \item 第一段 @{verbatim "m_fault"}：可能\emph{故障}（fault）；
    \item 第二段 @{verbatim "m_error"}：可能\emph{出错}（error，返回错误码）；
    \item 第三段 @{verbatim "m_finalise"}：真正提交，可能被\emph{抢占}。
  \end{itemize}
  前两段都只做检查与解码，只有第三段会改状态。
\<close>

datatype 'a phase_fault = Faulted fault | NoFault 'a

datatype 'a phase_error = Errored nat | NoError 'a

definition syscall3 ::
  "fault option \<Rightarrow> (fault \<Rightarrow> 'r) \<Rightarrow> (nat + 'a) \<Rightarrow> (nat \<Rightarrow> 'r) \<Rightarrow> ('a \<Rightarrow> 'r) \<Rightarrow> 'r" where
  "syscall3 mf hf me he mf2 \<equiv> case mf of
      Some f \<Rightarrow> hf f
    | None \<Rightarrow> (case me of
          Inl e \<Rightarrow> he e
        | Inr a \<Rightarrow> mf2 a)"

lemma fault_wins:
  "mf = Some f \<Longrightarrow> syscall3 mf hf me he mf2 = hf f"
  by (simp add: syscall3_def)

lemma fault_shadows_error:
  "mf = Some f \<Longrightarrow> me = Inl e \<Longrightarrow> syscall3 mf hf me he mf2 = hf f"
  by (simp add: syscall3_def)

lemma error_when_no_fault:
  "mf = None \<Longrightarrow> me = Inl e \<Longrightarrow> syscall3 mf hf me he mf2 = he e"
  by (simp add: syscall3_def)

lemma finalise_when_all_ok:
  "mf = None \<Longrightarrow> me = Inr a \<Longrightarrow> syscall3 mf hf me he mf2 = mf2 a"
  by (simp add: syscall3_def)

text \<open>
  @{thm fault_shadows_error} 说明的是\emph{优先级}：故障比错误先被处理。
  真实内核里这决定了用户最终看到的是 fault 消息还是错误码——
  顺序写错，ABI 就错了。
\<close>

subsection \<open>9.3 handle_invocation 的三步\<close>

text \<open>
  @{verbatim "Syscall_A.thy"} 第 121 行起描述的 @{verbatim "handle_invocation"}
  是三段式的一个实例：

  \begin{enumerate}
    \item \emph{查能力}：调用者有没有出示正确的能力（@{verbatim "lookup_cap_and_slot"}）；
    \item \emph{解码}：把用户字变成 @{verbatim "invocation"} 结构（@{verbatim "decode_invocation"}）；
    \item \emph{执行}：@{verbatim "perform_invocation"}（第 154 行）。
  \end{enumerate}

  模型把这三层压缩成一个函数，保留"失败在哪一层"这个信息。
\<close>

datatype invocation = InvokeEndpoint nat | InvokeCNodeOp nat | InvokeTCBOp nat

datatype invoke_result = Ok | NoCapability | BadArguments | Failed

definition handle_invocation :: "bool \<Rightarrow> nat \<Rightarrow> invocation option \<Rightarrow> invoke_result" where
  "handle_invocation has_cap label decoded \<equiv>
     if \<not> has_cap then NoCapability
     else if decoded = None then BadArguments
     else Ok"

lemma no_cap_short_circuits:
  "handle_invocation False label d = NoCapability"
  by (simp add: handle_invocation_def)

lemma bad_args_after_cap:
  "handle_invocation True label None = BadArguments"
  by (simp add: handle_invocation_def)

lemma ok_needs_both:
  "handle_invocation True label (Some i) = Ok"
  by (simp add: handle_invocation_def)

subsection \<open>9.4 事件分发：中断不该碰到 CSpace\<close>

text \<open>
  最后看 @{verbatim "handle_event"} 的分发。模型里让每个事件返回"它做了什么"，
  于是可以证明：中断不进入能力调用路径。
\<close>

datatype action = DoInvocation syscall | DoFault fault | DoInterrupt nat | DoNothing

definition handle_event :: "event \<Rightarrow> action" where
  "handle_event e \<equiv> case e of
      SyscallEvent s \<Rightarrow> if is_invocation s then DoInvocation s else DoNothing
    | FaultEvent f    \<Rightarrow> DoFault f
    | InterruptEvent i \<Rightarrow> DoInterrupt i"

lemma interrupt_never_invokes:
  "handle_event (InterruptEvent i) = DoInterrupt i"
  by (simp add: handle_event_def)

lemma yield_does_not_invoke:
  "handle_event (SyscallEvent SysYield) = DoNothing"
  by (simp add: handle_event_def is_invocation_def)

lemma send_invokes:
  "handle_event (SyscallEvent SysSend) = DoInvocation SysSend"
  by (simp add: handle_event_def is_invocation_def)

text \<open>
  这条"中断不动 CSpace"看起来显然，但在规范里是要证的：
  @{verbatim "Interrupt_A.thy"} 里的中断处理只碰 IRQ 槽与通知对象，
  证明时必须把它与 @{verbatim "handle_invocation"} 分开。
\<close>

ML \<open>
  writeln (@{make_string} @{thm fault_shadows_error});
  writeln (@{make_string} @{thm interrupt_never_invokes})
\<close>

ML \<open>writeln "==== 09 结束 ===="\<close>

end
