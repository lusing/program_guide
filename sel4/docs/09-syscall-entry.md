# 09 · 系统调用入口

对应示例：`../examples/S09_syscall_entry.thy`

## 9.1 内核只有一个入口

用户发起一次系统调用之后，内核走同一条路：判断这是什么事件 → 处理 fault →
解码 → 执行 → 收尾。真实入口是 `l4v/spec/abstract/Syscall_A.thy` 的
`call_kernel`（第 376 行）/ `handle_event`（第 325 行）/
`handle_invocation`（第 213 行）/ `perform_invocation`（第 154 行）；
C 侧在 `seL4/src/api/syscall.c`。

`handle_event` 分派的是 `event`。真实 `event` 有六个构造子，写在
`l4v/spec/haskell/src/SEL4/API/Syscall.lhs` 第 43 行
（Isabelle 侧的 `Event_H` 由它生成，不在这棵仓库里）：
`SyscallEvent`、`UnknownSyscall`、`UserLevelFault`、`Interrupt`、
`VMFaultEvent`、`HypervisorEvent`。注意 `Interrupt` **不带参数**——
中断号在进内核时已经被换成具体的 handler 能力了。

同一文件第 58 行的 `Syscall` 有八个构造子，与
`seL4/libsel4/include/api/syscall.xml` 的 `<api-master>` 一节逐字对应：
`Call`、`ReplyRecv`、`Send`、`NBSend`、`Recv`、`Reply`、`Yield`、`NBRecv`。
**没有 `Poll`**——别按其它微内核的习惯猜。MCS 分支另外加
`NBSendRecv`/`NBSendWait`/`Wait`/`NBWait`。

先分清哪些系统调用算"调用"（实测）：

```text
theorem
  only_three_syscalls_invoke:
    is_invocation ?s \<Longrightarrow> ?s = SysSend \<or> ?s = SysNBSend \<or> ?s = SysCall

theorem nbsend_is_an_invocation: is_invocation SysNBSend
```

进"调用一个对象的方法"这条路的有**三个**：`SysSend`、`SysNBSend`、`SysCall`。
`SysRecv` / `SysYield` / `SysReply` / `SysReplyRecv` / `SysNBRecv` 不走这条路。

## 9.2 三段式：fault / error / finalise

`l4v/spec/abstract/Syscall_A.thy` 第 84--101 行是整个入口的骨架，签名和定义一起抄下来：

<!-- 源码块：l4v/spec/abstract/Syscall_A.thy:84-101 -->
```text
definition
  syscall :: "('a,'z::state_ext) f_monad
                  \<Rightarrow> (fault \<Rightarrow> ('c,'z::state_ext) s_monad)
                  \<Rightarrow> ('a \<Rightarrow> ('b,'z::state_ext) se_monad)
                  \<Rightarrow> (syscall_error \<Rightarrow> ('c,'z::state_ext) s_monad)
               \<Rightarrow> ('b \<Rightarrow> ('c,'z::state_ext) p_monad) \<Rightarrow> ('c,'z::state_ext) p_monad"
where
"syscall m_fault h_fault m_error h_error m_finalise \<equiv> doE
    r_fault \<leftarrow> without_preemption $ m_fault;
    case r_fault of
          Inl f \<Rightarrow>   without_preemption $ h_fault f
        | Inr a \<Rightarrow>   doE
            r_error \<leftarrow> without_preemption $ m_error a;
            case r_error of
                  Inl e \<Rightarrow>   without_preemption $ h_error e
                | Inr b \<Rightarrow>   m_finalise b
        odE
odE"
```

签名（第 85--89 行）里四段的单子各不相同：`m_fault` 是 `f_monad`，两个 handler 是 `s_monad`，
`m_error` 是 `se_monad`，只有 `m_finalise` 是 `p_monad`——返回值也是 `p_monad`。
三点要看准（源码块）：故障与错误都用 `sum` 表示（`Inl` 才是失败），不是 option；
`m_error` 是**依赖于**第一段结果的函数 `m_error a`；四段全被
`without_preemption` 包着，**只有 `m_finalise b` 没有**——可抢占的只有提交那一步。

模型的优先级（实测）：

```text
theorem fault_wins: syscall3 (Inl ?f) ?hf ?me ?he ?mf2.0 = ?hf ?f

theorem
  fault_shadows_error:
    syscall3 (Inl ?f) ?hf ?me ?he ?mf2.0 =
    syscall3 (Inl ?f) ?hf ?me' ?he ?mf2.0
```

`fault_shadows_error` 是更强的说法：**一旦有 fault，结果连 `m_error` 换成谁都不在乎**。
即使解码本来会报错，回报给用户的仍然是 fault。顺序是被证明固定下来的，
不是"随手挑一个"。

## 9.3 handle_invocation：三段怎么被两个布尔开关拧起来

`handle_invocation :: bool ⇒ bool ⇒ _ p_monad`（第 213 行）就是 `syscall`
组合子的一个实例，两个参数依次是 `calling` 与 `blocking`。两段处理器分别被
这两个开关拧着：故障处理是 `when blocking $ handle_fault thread fault`（第 228 行），
错误处理是 `when calling $ reply_from_kernel thread $ msg_from_syscall_error err`
（第 233 行）。最后一段调的是 `perform_invocation blocking calling oper`——
**参数顺序翻了**。

于是同一个失败，不同系统调用报给用户的东西不一样（实测）：

```text
theorem
  fault_reported_only_when_blocking:
    handle_invocation ?calling True (Inl ?f) ?r_error = SawFault

theorem
  fault_swallowed_when_nonblocking:
    handle_invocation ?calling False (Inl ?f) ?r_error = Silent

theorem
  error_swallowed_when_not_calling:
    ?r_error ?a = Inl ?e \<Longrightarrow>
    handle_invocation False ?blocking (Inr ?a) ?r_error = Silent
```

对上第 9.4 节那三个开关就得到一个真实现象：`seL4_Send` 出错时用户寄存器里
看不到错误码，只有 `seL4_Call` 才有返回值的 ABI 约定——
这道闸在规范里就是那个 `calling` 开关（`l4v/spec/abstract/Syscall_A.thy` 第 233 行）。

## 9.4 事件分发：中断不该碰到 CSpace

`handle_event` 的八支是逐条写死的（第 327--339 行）：`SysSend` 走
`handle_send True`、`SysNBSend` 走 `handle_send False`、`SysCall` 走 `handle_call`，
其余五支走各自的处理器。加上第 262--267 行的
`handle_send bl ≡ handle_invocation False bl` 与
`handle_call ≡ handle_invocation True True`，
"谁进能力调用路径"就有了精确答案。模型把这条分类学写成（实测）：

```text
theorem
  non_invocation_syscalls_never_touch_cspace:
    \<not> is_invocation ?s \<Longrightarrow> \<not> touches_cspace (handle_event (SyscallEvent ?s))

theorem
  interrupt_never_touches_cspace: \<not> touches_cspace (handle_event Interrupt)
```

**中断路径不查任何能力**——否则中断就成了绕过能力检查的后门。
这条看起来显然，但在规范里是要证的：`l4v/spec/abstract/Interrupt_A.thy` 的中断处理
与 `handle_invocation` 属于不同的 development，证明时必须把两边作用域分开。

---

## 官方教程对照

官方 [fault-handlers](https://docs.sel4.systems/Tutorials/fault-handlers.html)
（抓取日期 2026-09-25）的原话是："when a thread generates a thread fault, the kernel
will block the faulting thread's execution and attempt to deliver a message across a
special endpoint associated with that thread, called its 'fault handler' endpoint."
这句话在 C 里就是 `tcbFaultHandler` 那个槽——MCS 版的
`handleFault`（`seL4/src/kernel/faulthandler.c:15`）第二行就是
`cap_t faultHandlerCap = TCB_PTR_CTE_PTR(tptr, tcbFaultHandler)->cap;`。
下面四条是这一页没讲、却正好是本章主线的东西。

**1. "fault 优先于 error"在代码里就是一个函数的书写顺序。**
入口函数 `handleInvocation` 在 `seL4/src/api/syscall.c:300`（MCS 版；
非 MCS 是同名的另一版，`:302`，形参少了 `canDonate`/`firstPhase`/`cptr` 三个），
它开头的顺序（`seL4/src/api/syscall.c:320--324`）是：先 `lookupCapAndSlot`，
失败就造 CapFault；再 `lookupIPCBuffer` + `lookupExtraCaps`，失败还是走 fault；
**然后**才 `seL4_MessageInfo_get_length` 检查长度、`decodeInvocation` 解码。
也就是说 9.2 节那张"fault → error → 执行"的三段表不是抽象层的发明，
是这段 C 代码从上往下读出来的。抽象规范把它写成两个布尔开关，
代码把它写成 return 的先后。

**2. CapFault 有两个来源点，靠一个布尔参数区分。**
`seL4/src/api/syscall.c:324` 那句 `seL4_Fault_CapFault_new(cptr, false)`
是"入口查不到能力"；`seL4/src/api/syscall.c:469--473` 的
`seL4_Fault_CapFault_new(epCPtr, true)` 是"收端权利不足"。
第二个实参是 inReceivePhase——**同一个 fault 类型，用载荷里的一个位说"我死在 send 还是 recv"**。
第 10 章解码那一节会看到这条位最后落在 `seL4_CapFault_InRecvPhase` 这个 MR 下标上。

**3. 有一处内核宁可截断也不返回错误，理由是"不是所有传输点都有资格报错"。**
`seL4/src/api/syscall.c:346--354` 的 `n_msgRegisters` 截断分支值得逐字读：

```c
    if (unlikely(length > n_msgRegisters && !buffer)) {
        /* If no IPC buffer is present the kernel truncates the maximum message length to n_msgRegisters.
         * The kernel truncates rather than returns because not all message transfer points in the kernel
         * are allowed to return an error.
         */
```

本章 9.3 说"失败即不 `valid`"，讲霍尔逻辑那一层；
而这里 C 做的是**另一件事**：把"失败"改写成"成功但少传"。
所以 `no_fail` 类的前提在 C 侧不是免费的——`userError` 只留了一条串口警告。

**4. "没有 fault handler 会怎样"两种内核不一样。**
MCS 走 `handleNoFaultHandler`（`seL4/src/kernel/faulthandler.c:146`），
master 走 `handleDoubleFault`（`seL4/src/kernel/faulthandler.c:149`），
两者共用同一个函数体，只是形参不同；
148 行那句注释 "The second fault, ex2, is stored in the global `current_fault`"
说清了 master 为什么需要两个 fault：**它可能在自己送 fault 的路上又撞一个 fault**。
官方教程那句"the kernel will simply suspend the faulting thread"
描述的是 MCS 的行为，master 下你会看到串口上的 double fault 打印。

> 另外两处"C↔规范对齐"的硬钉子值得知道：
> `seL4/src/api/faults.c:24--26` 用三个 `compile_assert` 把
> `n_syscallMessage`、`n_exceptionMessage` 与用户态的
> `seL4_UnknownSyscall_Syscall` 等下标绑死——**用户可见的 MR 编号与内核内部
> 的寄存器个数必须逐项相等**，否则编译失败。
> 这类断言是"为什么第 19 章的 C 规范能对上 C 代码"的一个现场证据。

---

## 本章坑位清单（实测）

1. **把 invocation 路径数成两条**：`SysSend`、`SysNBSend`、`SysCall` 是三条（第 329--331 行逐条写死）。
2. **以为 fault 与 error 可以任意挑一个回报**：`fault_wins` 把顺序固定成 fault > error。
3. **漏掉两个 `when` 开关**：fault 只在 `blocking` 时报、error 只在 `calling` 时报（第 228、233 行）。
4. **把 `handle_event` 与 `handle_invocation` 混用**：前者分派事件类别，后者只处理调用。
5. **以为所有系统调用都会走解码**：中断、yield、recv 根本不进解码路径。
6. **照抄 `SysPoll`**：master API 八个构造子里没有它（`syscall.xml`）。
7. **以为 `Interrupt` 事件带中断号**：它是无参构造子。
8. **给 `syscall` 组合子用 option 建模**：真实用的是 `sum`，`Inl` 才是失败。
9. **以为三段都可抢占**：只有 `m_finalise` 没被 `without_preemption` 包着。
10. **`perform_invocation` 的参数顺序照抄**：它是 `(blocking, calling)`，与 `handle_invocation` 相反。
11. **在 `seL4/src/kernel/` 下找系统调用入口**：入口是 `seL4/src/api/syscall.c` 的 `handleSyscall`（第 562 行）。

---

上一章：[08 · 错误单子与解码](08-error-monad.md) ｜ 下一章：[10 · 解码器](10-decode.md) ｜ 返回：[README](../README.md)
