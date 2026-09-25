# 13 · 线程控制块

对应示例：`../examples/S13_tcb.thy`

## 13.1 TCB：内核眼里的"线程"

线程控制块（TCB）是 seL4 里最"重"的对象。`l4v/spec/abstract/Structures_A.thy`
第 388 行的 record 里，**前五个字段全是能力**：
`tcb_ctable`（CSpace 根）、`tcb_vtable`（VSpace 根）、`tcb_reply`、
`tcb_caller`、`tcb_ipcframe`；之后才是 `tcb_state`、`tcb_fault_handler`、
`tcb_ipc_buffer`、`tcb_fault`、`tcb_bound_notification`、`tcb_mcpriority`、
`tcb_priority`、`tcb_time_slice`、`tcb_domain`、`tcb_flags`、`tcb_arch`。

也就是说 TCB 本身就是 CSpace 里的一类对象：
`CSpaceAcc_A.thy` 第 44 行的 `set_cap` 为它单列一支。
操作在 `l4v/spec/abstract/Tcb_A.thy`，访问器在 `TcbAcc_A.thy`，
C 侧 `seL4/src/object/tcb.c`。

## 13.2 线程状态：八个构造子，两个带载荷

`Structures_A.thy` 第 362--370 行的 `thread_state` 有八个构造子，
其中 `BlockedOnReceive obj_ref receiver_payload` 与
`BlockedOnSend obj_ref sender_payload` 各带**两个**参数：
线程睡着时，"当时正在跟谁说话"必须留在状态里，
否则取消 IPC（第 11 章的 `cancel_ipc`）就找不到该通知谁。

## 13.3 可运行性：只有两个状态算"能上 CPU"

`runnable` 定义在 `l4v/spec/abstract/Structures_A.thy` 第 409 行，
是一条把八个状态逐个列出来的 `primrec`：

```text
theorem running_is_runnable: runnable Running
```

```text
theorem restart_is_runnable: runnable Restart
```

```text
theorem inactive_is_not_runnable: \<not> runnable Inactive
```

```text
theorem
  blocked_is_not_runnable:
    \<not> runnable (BlockedOnSend ?p ?x) \<and>
    \<not> runnable (BlockedOnReceive ?p ?x) \<and>
    \<not> runnable BlockedOnReply \<and> \<not> runnable (BlockedOnNotification ?p)
```

```text
theorem idle_is_not_runnable: \<not> runnable IdleThreadState
```

`runnable` 是**谓词**，不是状态构造子。调度器（第 14 章）只从 `runnable`
的线程里挑。`Inactive` 是"被人挂起、等着唤醒"，
`IdleThreadState` 是每个域里那个"没活干时空转"的线程——
两个"停着"的状态待遇不同。

## 13.4 TCB 记录与 `thread_set`

内核里对 TCB 的修改全都经由 `l4v/spec/abstract/KHeap_A.thy` 第 63 行的
`thread_set`：它取一个 `tcb ⇒ tcb` 这样的**函数**作为参数。
同文件第 247 行的 `thread_set_priority`、第 251 行的 `thread_set_time_slice`
都是在它上面套一个 record 更新。模型保留"更新函数"这个形状：

```text
theorem
  set_state_changes_only_state:
      tcb_state (thread_set (set_thread_state ?ts) ?t) = ?ts
      tcb_priority (thread_set (set_thread_state ?ts) ?t) = tcb_priority ?t
      tcb_ctable (thread_set (set_thread_state ?ts) ?t) = tcb_ctable ?t
```

```text
theorem
  thread_set_composes:
    thread_set ?f (thread_set ?g ?t) = thread_set (?f \<circ> ?g) ?t
```

**注意 `thread_set` 不幂等**：`thread_set f (thread_set f t) = thread_set f t`
对任意的 `f :: tcb ⇒ tcb` 根本不成立——`f` 完全可以是"把优先级加一"。
真实证明里靠的是"只动一个字段"，不是幂等。

这类"改了一处、别处不动"的定理在 seL4 的证明里通常不用手写——
`l4v/lib/Crunch.thy`（配合 `crunch-cmd.ML`）与
`l4v/lib/AddUpdSimps.thy` 会批量生成。

## 13.5 挂起与唤醒：两个都有前提

真实 `suspend`（`l4v/spec/abstract/IpcCancel_A.thy` 第 368 行）做四件事：
先 `cancel_ipc`；正在 `Running` 才 `update_restart_pc`；
然后 `tcb_sched_dequeue`；最后置 `Inactive`。

"唤醒"那一半在规范里**不叫 `resume`，叫 `restart`**
（`Tcb_A.thy` 第 42 行），而且整条被
`when (¬ runnable state ∧ ¬ idle state)` 包着：

```text
theorem
  restart_on_running_is_noop: runnable (tcb_state ?t) \<Longrightarrow> restart ?t = ?t
```

```text
theorem
  restart_on_idle_is_noop: idle_state (tcb_state ?t) \<Longrightarrow> restart ?t = ?t
```

```text
theorem
  restart_makes_runnable:
    \<not> idle_state (tcb_state ?t) \<Longrightarrow> runnable (tcb_state (restart ?t))
```

```text
theorem
  restart_on_blocked_sets_restart_state:
    tcb_state ?t = BlockedOnReply \<Longrightarrow> tcb_state (restart ?t) = Restart
```

```text
theorem
  suspend_then_restart_state: tcb_state (restart (suspend ?t)) = Restart
```

第二条实测最有价值：**对正在运行的线程调用 resume 是空操作**。
若没有这个闸，任何持有 TCB 能力的线程都能把别人打断。
第三条也值得停一下：挂起再唤醒之后状态是 `Restart` 而不是 `Running`——
`Restart` 表示"从头开始跑"，和被中断后原地继续是两回事。

`restart` 里的 `idle` 判断在模型里列成与 `runnable` 对称的一张表：

```text
theorem idle_state_is_idle_thread: idle_state ?ts = (?ts = IdleThreadState)
```

真正的坑在调度队列：`suspend` 里的 `tcb_sched_dequeue` 与
`restart` 里的 `tcb_sched_enqueue` 必须配对，
顺序错了就会出现"不在队列里却可运行"的幽灵线程。
第 17 章的不变式就是用来排除它的。

## 13.6 TCB 只有五个能力槽

`tcb_cnode_index` 的定义在 `Structures_A.thy` 第 615 行：
`"tcb_cnode_index n ≡ to_bl (of_nat n :: 3 word)"`——
它是一个**三位**向量的位列表。用它的是
`CSpaceAcc_A.thy` 第 53--61 行那一串
`if cref = tcb_cnode_index 0 then … tcb_ctable …`，
只有 0--4 五个索引有分支，第六个直接 `fail`：

```text
theorem
  slot_zero_is_ctable: update_tcb_slot ?c 0 ?t = Some (?t\<lparr>tcb_ctable := ?c\<rparr>)
```

```text
theorem
  slot_four_is_ipcframe:
    update_tcb_slot ?c 4 ?t = Some (?t\<lparr>tcb_ipcframe := ?c\<rparr>)
```

```text
theorem slot_five_is_rejected: update_tcb_slot ?c 5 ?t = None
```

```text
theorem only_five_slots: 5 \<le> ?n \<Longrightarrow> update_tcb_slot ?c ?n ?t = None
```

```text
theorem
  accepted_slot_never_touches_state:
    update_tcb_slot ?c ?n ?t = Some ?t' \<Longrightarrow>
    ?n < 5 \<and> tcb_state ?t' = tcb_state ?t
```

这五个槽不是摆设。`setup_reply_master`（`Tcb_A.thy` 第 30 行）
只在 2 号槽为 `NullCap` 时才写入一条 master reply 能力
（`ReplyCap thread True`，权利是 AllowGrant 与 AllowWrite）；
而 `setup_caller_cap`（`Ipc_A.thy` 第 289--290 行）用 `cap_insert`
（`CSpace_A.thy` 第 762 行）把 `ReplyCap sender False`
插进**接收者**的 3 号槽，源槽正是发送者的 2 号槽。
第 12 章"reply 不可复制"说的是用户态；内核在 Call 的那一刻自己派生这份非主副本。

第 04 章的 `lookup_slot_for_thread` 就是从 0 号槽出发解析能力地址的。

---

## 官方教程对照

官方 [threads](https://docs.sel4.systems/Tutorials/threads.html) 一页
（抓取日期 2026-09-25）教的是怎么**搭**一个线程：Retype 出 TCB、从 untyped 切出栈与
IPC buffer、再 `seL4_TCB_Configure`。这条流程本章不管；本章管的是"这次调用进了内核之后
发生什么"。下面几条官方页都没写，C 侧却写得明明白白。

**1. `Configure` 在接口定义里是两个方法。** `TCBConfigure`
（`seL4/libsel4/include/interfaces/object-api.xml:182`）的条件是
`CONFIG_KERNEL_MCS` 取反（`seL4/libsel4/include/interfaces/object-api.xml:183`），
MCS 那份的 `manual_label` 是 `tcb_configure_mcs`
（`seL4/libsel4/include/interfaces/object-api.xml:227`）。
两张参数表唯一的差别就是 `fault_ep`（`seL4/libsel4/include/interfaces/object-api.xml:190`）：
master 有、MCS 没有；MCS 要改 fault endpoint 得用 `SetSpace`
（`seL4/libsel4/include/interfaces/object-api.xml:499`）。
C 侧把这个差别写成字面量：`TCBCONFIGURE_ARGS`（`seL4/src/object/tcb.c:1104--1108`）
MCS 下 3、master 下 4，多的正是 `faultEP`（`seL4/src/object/tcb.c:1122`）那一个字。

**2. 签名里七个参数，消息寄存器里只有四个。** 内核从 buffer 里取三个字：
`cRootData`、`vRootData`、`bufferAddr`（`seL4/src/object/tcb.c:1117--1125`），
另外三份能力（CSpace 根、VSpace 根、buffer 所在页）走第 10 章的 extra caps 通道，
即 `current_extra_caps`（`seL4/src/object/tcb.c:1128--1133`）。
截断判定同时看这两路：字数不够**或**第三份 extra cap 为 `NULL` 都是
`seL4_TruncatedMessage`（`seL4/src/object/tcb.c:1109--1115`）。

**3. `buffer` 传 0 合法，但那份能力照样得带。** `bufferAddr` 为 0 时内核把
`bufferSlot` 直接置 `NULL`（`seL4/src/object/tcb.c:1135--1137`），连
`deriveCap`（`seL4/src/object/tcb.c:1138`）都不做；
可上面那条截断检查仍然要求第三份 excap 非空。
所以"这个线程不要 IPC buffer"在协议层是"一个字写 0 + 一份（哪怕是 NullCap）能力"，
不是"少传一个参数"。之后才轮到 `checkValidIPCBuffer`
（`seL4/src/object/tcb.c:1144`）把关。

**4. IPC buffer 的规矩由 arch 代码把关。** XML 里那句 `description`
（`seL4/libsel4/include/interfaces/object-api.xml:201--202`）说的是
"Must be aligned to … The IPC buffer may not cross a page boundary"，
干活的是 `checkValidIPCBuffer`——它在每个 arch 的 vspace 里各有一份实现
（x86 那份在 `seL4/src/arch/x86/kernel/vspace.c:651`，arm64 在
`seL4/src/arch/arm/64/kernel/vspace.c:738`）。buffer 尺寸由每 sel4_arch 的宏定：
32 位的 `seL4_IPCBufferSizeBits`（
`seL4/libsel4/sel4_arch_include/aarch32/sel4/sel4_arch/constants.h:251`）是 9，
64 位的 `seL4_IPCBufferSizeBits`（
`seL4/libsel4/sel4_arch_include/aarch64/sel4/sel4_arch/constants.h:241`）是 10，，
即 512 与 1024 字节——刚好装得下第 11 章那个上限 120 字的消息
（64 位 120 × 8 = 960 字节）。

**5. 配 CSpace 根之前，先问"它是不是正在被删"。** `slotCapLongRunningDelete`
（`seL4/src/object/tcb.c:1150--1157`）对 `tcbCTable` 与 `tcbVTable` 各查一次，
命中就是 `seL4_IllegalOperation`。这正是第 06 章 Zombie 的可见后果：
一个正在被拆的 CNode 不能同时被别人装成线程的 ctable。

**6. 优先级不是"设成什么"，是"设成不超过我 MCP"。** `checkPrio`
（`seL4/src/object/tcb.c:32`）读授权者的 `tcbMCP`（`seL4/src/object/tcb.c:36`），
只有一句比较：`prio` 大于它就是 `seL4_RangeError`（`seL4/src/object/tcb.c:42--47`），
并把 `rangeErrorMin/Max` 填成 `seL4_MinPrio` 与 mcp。它的上一行是
`assert`（`seL4/src/object/tcb.c:39`）加注释
"system invariant: existing MCPs are bounded"——**自己的** MCP 有界这件事内核不检查，
它信第 17 章的不变式。API 侧的上界就是 `seL4_MaxPrio`
（`seL4/libsel4/include/sel4/constants.h:46--47`），等于 `CONFIG_NUM_PRIORITIES - 1`。

**7. 读寄存器有三道失败，顺序固定。** `decodeReadRegisters`
（`seL4/src/object/tcb.c:998`）先看字数（`length < 2` →
`seL4_TruncatedMessage`，`seL4/src/object/tcb.c:1004--1008`），再看个数
（`n < 1 || n > n_frameRegisters + n_gpRegisters` → `seL4_RangeError`，
`seL4/src/object/tcb.c:1013--1021`），最后才看身份：读自己是
`seL4_IllegalOperation`（`seL4/src/object/tcb.c:1026--1030`）。
第三条常被忘：**一个线程不能读自己的寄存器**，要调试自己得让别人来读。
上限随 arch 差好几倍：arm64 的 `n_frameRegisters`
（`seL4/include/arch/arm/arch/64/mode/machine/registerset.h:167`）是 17、
`n_gpRegisters`（`seL4/include/arch/arm/arch/64/mode/machine/registerset.h:168`）是 19；
x86-64 的 `n_frameRegisters`
（`seL4/include/arch/x86/arch/64/mode/machine/registerset.h:79`）是 18、
`n_gpRegisters`（`seL4/include/arch/x86/arch/64/mode/machine/registerset.h:80`）只有 2；
riscv 的 `n_gpRegisters`（`seL4/include/arch/riscv/arch/machine/registerset.h:80`）是 16。

**8. XML 的 `suspend_source` 在总线上不是一个字。** `ReadRegisters`
（`seL4/libsel4/include/interfaces/object-api.xml:88`）把它列成第一个参数，
内核却把它当 flags 的 0 号位读：`enum ReadRegistersFlags`
（`seL4/src/object/tcb.c:994--996`）只有 `ReadRegisters_suspend = 0` 一项，
取的时候用 `ReadRegisters_suspend` 这一位（`seL4/src/object/tcb.c:1035`），
而 `Arch_decodeTransfer`（`seL4/src/object/tcb.c:1023`）拿的是 `flags >> 8`。
也就是说 C 侧一个 `flags` 字被拆成两段用——第 10 章"参数在总线上是字"的又一例。

**9. 名字里的类型全是别名。** `seL4_CNode`
（`seL4/libsel4/include/sel4/types.h:35`）、`seL4_IRQHandler`
（`seL4/libsel4/include/sel4/types.h:36`）、`seL4_TCB`
（`seL4/libsel4/include/sel4/types.h:38`）都是 `seL4_CPtr` 的别名，
而 `seL4_CPtr`（`seL4/libsel4/include/sel4/simple_types.h:128`）本身就是 `seL4_Word`。
因此 master 的 `SetSpace` 把 `fault_ep`
（`seL4/libsel4/include/interfaces/object-api.xml:470`）写成 `seL4_Word`、
MCS 那份写成 `seL4_CPtr`（`seL4/libsel4/include/interfaces/object-api.xml:507`）
**没有任何语义差别**，纯粹是文档口径。别按名字推宽度。

---

## 本章坑位清单（实测）

1. **把 `runnable` 当状态构造子**：它是谓词，`Running` 与 `Restart` 都满足。
2. **以为 `resume` 会打断正在跑的线程**：`restart_on_running_is_noop`，规范里那是空操作。
3. **以为规范里有个叫 `resume` 的函数**：规范侧叫 `restart`（`Tcb_A.thy:42`），
   `seL4_TCB_Resume` 只是用户态的名字。
4. **以为挂起再恢复回到 `Running`**：实测 `suspend_then_restart_state` 给的是 `Restart`。
5. **以为 `thread_set f` 幂等**：`f` 是任意函数，幂等根本不成立；要的是"只动一处"。
6. **改状态时顺手改了别的字段**：用 `accepted_slot_never_touches_state` 这类引理钉住无关字段。
7. **把 `Inactive` 与 `IdleThreadState` 混为一谈**：一个是用户线程被挂起，一个是内核空转线程。
8. **以为 TCB 有任意多个能力槽**：只有 0--4 五个，`slot_five_is_rejected`。
9. **忘了 ctable 是 0 号槽**：解析线程的 CSpace 要从 `tcb_cnode_index 0` 出发。
10. **把 `BlockedOnReceive` 当一个参数的构造子**：它带端点引用**加**载荷，
    取消 IPC 时靠载荷找回对端。
11. **把优先级当无界整数**：`Structures_A.thy` 第 372 行 `type_synonym priority = word8`。
12. **找 TCB 实现找错文件**：C 侧 `seL4/src/object/tcb.c`，规范侧 `Tcb_A.thy`，访问器 `TcbAcc_A.thy`。
13. **按签名数字参数个数**：`Configure` 的七、六个参数里只有三、四个是消息寄存器，
    其余走 extra caps（见 13 章对照第 2 条）。
14. **以为 `buffer` 传 0 就能少传一份能力**：截断检查仍然要第三份 excap 非空。
15. **以为线程能读自己的寄存器**：`decodeReadRegisters` 对此给的是 `IllegalOperation`。
16. **以为 `seL4_CPtr` / `seL4_TCB` / `seL4_Word` 是三种东西**：全是同一个字的别名。

---

上一章：[12 · 通知与 Reply](12-notification.md) ｜ 下一章：[14 · 调度](14-schedule.md) ｜ 返回：[README](../README.md)
