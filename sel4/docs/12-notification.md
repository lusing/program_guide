# 12 · 通知与 Reply

对应示例：`../examples/S12_notification.thy`

## 12.1 通知：一组二元信号量

通知对象（notification）是 seL4 的**异步**信号机制，与同步的 IPC（第 11 章）互补。
规范里那段注释就写在数据类型上面（`l4v/spec/abstract/Structures_A.thy` 第 299 行）：

<!-- 源码块：l4v/spec/abstract/Structures_A.thy:299-301 -->

```text
text \<open>Notifications are sets of binary semaphores (stored in the
\emph{badge word}). Unlike endpoints, threads may choose to block waiting to
receive, but not to send.\<close>
```

一句话：**可以阻塞地收，不可以阻塞地发**。
C 侧全部逻辑在 `seL4/src/object/notification.c`，入口 `sendSignal` 在第 62 行。

## 12.2 状态：Idle / Waiting / Active

<!-- 源码块：l4v/spec/abstract/Structures_A.thy:303-310 -->

```text
datatype ntfn
           = IdleNtfn
           | WaitingNtfn "obj_ref list"
           | ActiveNtfn badge

record notification =
  ntfn_obj :: ntfn
  ntfn_bound_tcb :: "obj_ref option"
```

第 303--310 行的这两段就是本章的全部状态空间。模型（`../examples/S12_notification.thy`）
照抄形状，只把"徽章是一个机器字"换成"哪些位被置上"的集合。

```text
theorem fresh_notification_is_idle: ntfn_obj default_notification = IdleNtfn
```

```text
theorem
  empty_wait_queue_not_well_formed: \<not> ntfn_well_formed (WaitingNtfn [])
```

`WaitingNtfn` 里装的是一个**列表**——一个通知上可以同时挂多个等待者。
12.6 节会把这条和"绑定线程只有一个"摆在一起看。

## 12.3 累加：把按位或写成并集

两个徽章怎么合成一个？规范里 `combine_ntfn_badges` 的定义是一行
`combine_ntfn_badges ≡ semiring_bit_operations_class.or`
（`l4v/spec/abstract/ARM/Machine_A.thy` 第 96 行）；
C 里对应 `badge2 |= badge;`（`seL4/src/object/notification.c` 第 186 行）。

```text
theorem combine_idempotent: combine ?s ?s = ?s
```

```text
theorem combine_commutes: combine ?a ?b = combine ?b ?a
```

```text
theorem combine_never_loses_a_bit: ?s \<subseteq> combine ?s ?s'
```

幂等 + 可交换 = **"通知不是计数信号量"**：同一个位发多少次都只算一次。
想知道发生了几次，就得给每次发**不同**的位。

## 12.4 发送：四条分支

`Ipc_A.thy` 第 461 行的 `send_signal` 把通知状态分成四种处理：
空闲→置 Active；有人排队→唤醒队首；已经 Active→并徽章。
第四条（绑定线程恰好阻塞在 receive 上）要看线程状态，那是第 13 章的对象。

```text
theorem
  send_to_idle_signals:
    send_signal ?b (mk_ntfn IdleNtfn ?t) =
    (mk_ntfn (ActiveNtfn ?b) ?t, Signalled)
```

```text
theorem
  send_wakes_head_of_queue:
    send_signal ?b (mk_ntfn (WaitingNtfn [?q]) ?t) =
    (mk_ntfn IdleNtfn ?t, Woke ?q)
```

```text
theorem
  send_keeps_rest_of_queue:
    send_signal ?b (mk_ntfn (WaitingNtfn [?q1.0, ?q2.0]) ?t) =
    (mk_ntfn (WaitingNtfn [?q2.0]) ?t, Woke ?q1.0)
```

```text
theorem
  send_on_active_merges:
    send_signal ?b (mk_ntfn (ActiveNtfn ?b') ?t) =
    (mk_ntfn (ActiveNtfn (?b \<union> ?b')) ?t, Merged)
```

模型里多出来的 `Asserted` 一支对应规范
`update_waiting_ntfn` 开头那句 `assert (queue ≠ [])`
（`l4v/spec/abstract/Ipc_A.thy` 第 437 行）：实现**依赖**井形性才敢取队首。

```text
theorem
  well_formed_send_is_never_asserted:
    ntfn_well_formed (ntfn_obj ?n) \<Longrightarrow> snd (send_signal ?b ?n) \<noteq> Asserted
```

```text
theorem
  send_never_adds_a_waiter:
    length (waiting_queue (ntfn_obj (fst (send_signal ?b ?n))))
    \<le> length (waiting_queue (ntfn_obj ?n))
```

最后一条是"发送方从不阻塞"的另一种写法：发送这个动作本身不会往队列里添人。
端点那条规则（第 11 章）在这里反了过来。

## 12.5 接收：全取并清空

`Ipc_A.thy` 第 489 行 `receive_signal` 的 `ActiveNtfn` 分支是
`setRegister badge_register badge` 加 `ntfn_set_obj ntfn IdleNtfn`——
接收方**一次拿走整个徽章**，通知回到 Idle。这里**没有掩码**：
想挑走部分位，只能在发送时用不同的位。

```text
theorem
  receive_takes_the_whole_badge:
    receive_signal ?t ?b (mk_ntfn (ActiveNtfn ?s) ?t') =
    (mk_ntfn IdleNtfn ?t', Received ?s)
```

```text
theorem
  receive_resets_notification_to_idle:
    snd (receive_signal ?t ?b ?n) = Received ?s \<Longrightarrow>
    ntfn_obj (fst (receive_signal ?t ?b ?n)) = IdleNtfn
```

```text
theorem
  receive_appends_to_the_queue:
    receive_signal ?t True (mk_ntfn (WaitingNtfn ?q) ?b) =
    (mk_ntfn (WaitingNtfn (?q @ [?t])) ?b, Joined)
```

非阻塞且没有消息时走 `do_nbrecv_failed_transfer`（同文件第 370 行），
它把徽章寄存器写成 `0`——"没有消息"在寄存器层面就是一个真零。

写这条时有一个坑：**"没有消息"不能说成 `ntfn_obj n ≠ ActiveNtfn s`**，
那只是"不是某一个特定徽章"。所以要有一个显式谓词：

```text
theorem
  no_message_covers_idle_and_waiting:
    no_message IdleNtfn \<and> no_message (WaitingNtfn ?q)
```

```text
theorem active_is_a_message: \<not> no_message (ActiveNtfn ?s)
```

```text
theorem
  nonblocking_receive_without_message_changes_nothing:
    no_message (ntfn_obj ?n) \<Longrightarrow> fst (receive_signal ?t False ?n) = ?n
```

```text
theorem
  no_message_badge_is_zero:
    no_message (ntfn_obj ?n) \<Longrightarrow>
    badge_of_step (snd (receive_signal ?t False ?n)) = {}
```

一发一收合起来看：

```text
theorem
  send_then_receive_delivers_everything:
    ntfn_obj ?n = IdleNtfn \<Longrightarrow>
    receive_signal ?t True (fst (send_signal ?b ?n)) =
    (?n\<lparr>ntfn_obj := IdleNtfn\<rparr>, Received ?b)
```

## 12.6 绑定：一个绑定线程，多个等待者

这是本章最容易记反的一处。`ntfn_bound_tcb` 是 `obj_ref option`
（`l4v/spec/abstract/Structures_A.thy` 第 310 行）——**只**能绑一个线程；
但 `WaitingNtfn` 里装的是列表，等待者**可以有很多个**。
两者不是一回事：绑定回答"signal/reply 该叫谁"，队列回答"谁在等这个通知"。

绑定的实现 `bind_notification`（`l4v/spec/abstract/Tcb_A.thy` 第 135 行）
没有任何"已经绑过"的检查，它只是把两侧都改写成新值；
`seL4/src/object/notification.c` 第 380 行的 `bindNotification` 一字不差地照做。
反过来，**解绑**才有闸：`decode_unbind_notification`
（`l4v/spec/abstract/Decode_A.thy` 第 365 行）读到 `None` 就直接
`throwError IllegalOperation`。

```text
theorem
  bind_sets_the_bound_thread:
    ntfn_bound_tcb (bind_notification ?t ?n) = Some ?t
```

```text
theorem
  rebinding_just_moves_it:
    bind_notification ?t2.0 (bind_notification ?t1.0 ?n) =
    bind_notification ?t2.0 ?n
```

```text
theorem
  unbinding_an_unbound_thread_is_rejected:
    ntfn_bound_tcb ?n = None \<Longrightarrow> unbind_notification ?t ?n = None
```

```text
theorem
  unbinding_the_bound_thread_succeeds:
    unbind_notification ?t (bind_notification ?t ?n) =
    Some (?n\<lparr>ntfn_bound_tcb := None\<rparr>)
```

```text
theorem
  bound_field_holds_one_but_queue_holds_many:
    length (waiting_queue (WaitingNtfn [?a, ?b, ?c])) = 3
```

对照最后两条：同一个通知对象上，"绑给谁"是单值、"谁在等"是列表。

## 12.7 Reply 对象与一次性回答

```text
theorem
  reply_is_one_shot: consume_reply ?r = Some ?r' \<Longrightarrow> consume_reply ?r' = None
```

`seL4_Call` 会隐式创建一个 reply 能力，它只能用一次。
"一次性"在规范层面就一句话：`ReplyCap` 在 `derive_cap`
（`l4v/spec/abstract/CSpace_A.thy` 第 106 行）里派生成 `NullCap`——**不可复制**。
C 侧见 `seL4/src/object/reply.c`。

---

## 官方教程对照

官方 [notifications](https://docs.sel4.systems/Tutorials/notifications.html) 与
[interrupts](https://docs.sel4.systems/Tutorials/interrupts.html) 两页
（抓取日期 2026-09-25）。前一页给的那句比喻——"Notification objects can be seen as an
array of binary semaphores"——正是本章 12.1 的标题；
后一页让读者看到内核打印 "Undelivered IRQ: 42" 并说那是内核的警告。
两边都有一句话说得比实现松，下面钉住。

**1. "数组"是比喻，实现是一个字。** 通知对象里存信号的地方只有一个字
`ntfnMsgIdentifier`（`seL4/include/object/structures_64.bf:158`），
Active 状态下再来信号就做**按位或**：`sendSignal`
（`seL4/src/object/notification.c:62`）的 `NtfnState_Active` 分支
（`seL4/src/object/notification.c:182--189`）只把这个字读出来、或上去、写回去：

```c
        badge2 = notification_ptr_get_ntfnMsgIdentifier(ntfnPtr);
        badge2 |= badge;

        notification_ptr_set_ntfnMsgIdentifier(ntfnPtr, badge2);
```

所以"每个信号量一位"是对的，"**每个信号量一个等待者**"是错的——
等待者不占位，它在链表里：通知对象的结构里有排队用的
`ntfnQueue_head`（`seL4/include/object/structures_64.bf:160`）与
`ntfnQueue_tail`（`seL4/include/object/structures_64.bf:162`）。
**队列长度不受对象大小限制**，这一点本章 12.6"一个绑定线程 + 多个等待者"讲到了，
但没讲为什么队列能变长：因为队列节点住在 TCB 里，不住在通知里。

**2. `size_bits` 对通知对象不起作用。** 第 02 章的 `getObjectSize`
对 `seL4_NotificationObject` 直接返回 `seL4_NotificationBits`，
用户的请求值被丢掉；`notification_size_sane` 又把对象大小钉成 `2^bits` 字节。
也就是说**可累加的信号位数等于字长**（32 位机 32 个、64 位机 64 个），
不会因为你在 `seL4_Untyped_Retype` 里写了个更大的 `size_bits` 而变多。
官方 untyped 页把 `seL4_NotificationBits` 列进"要传 size_bits"的例子里，
那是历史遗留：早期版本确实有可变大小的通知。

**3. MCS 让通知大一倍，原因看得见。** `ntfnSchedContext`
（`seL4/include/object/structures_64.bf:153`）外面套着
`#ifdef CONFIG_KERNEL_MCS` 和 `padding 3 * word_size`；
非 MCS 编译时这 4 个字不存在。于是 64 位平台上通知从 4 个字
（32 字节 = `BIT(5)`）变成 8 个字（64 字节 = `BIT(6)`）——
第 02 章那张表里"MCS 那一支总大 1 位"的**全部原因**就是这里。

**4. IRQ 交付复用的就是 `sendSignal`。** 内核的 IRQ 分发走 `IRQSignal` 分支
（`seL4/src/object/interrupt.c:216--226`），查自己存的那份
通知能力，权利够就调 `sendSignal`（`seL4/src/object/interrupt.c:224`），badge 取自
`cap_notification_cap_get_capNtfnBadge`（`seL4/src/object/interrupt.c:225`）；
不够或类型不对就打印那句官方页引用过的
"Undelivered IRQ: %d"（`seL4/src/object/interrupt.c:228`，
要 `CONFIG_IRQ_REPORTING`）。
**注意 badge 不是内核按 IRQ 号填的**：内核只 OR 它手里那份能力的 badge。
"badge 等于 IRQ 号"是用户代码用 `CNodeMint`
（`seL4/libsel4/include/interfaces/object-api.xml:1011`，它比 Copy 多一个
`badge` 参数）派生能力时自己设的——
官方 interrupts 页的示例确实这么做了，但正文没把这条因果讲出来。

**5. 通知能力作为"额外能力"传进调用。** `IRQSetHandler` 要的那份通知能力
不是普通参数，而是从 `current_extra_caps.excaprefs[0]` 取的
（`seL4/src/object/interrupt.c:98--102`）：没带就是 `seL4_TruncatedMessage`，
类型不对或缺 send 权就是 `seL4_InvalidCapability`。
第 10 章"extra caps 全有或全无"在这里有一次真实出场。
（那两条 `userError` 里有一条写着 "does not have send rights on the **endpoint**"
——字符串是旧名遗留，见第 02 章 `seL4_AsyncEndpointObject` 那条 deprecated 别名。）

**6. 一次 `Signal` 与一次 `Call` 的区别在 C 里只是同一个 fastpath/slowpath。**
`seL4_Signal` 在 `seL4/libsel4/include/sel4/syscalls_master.h:178`，
`seL4_Wait` 在 `seL4/libsel4/include/sel4/syscalls_master.h:200`，
`seL4_Poll` 在 `seL4/libsel4/include/sel4/syscalls_master.h:228`——
三个都只是"把 badge 塞进消息"的薄封装，非 MCS 侧的文档注释里
直说了它们是 `Send`/`Recv`/`NBRecv` 的 convenience wrapper。
本章 12.4 那"四条分支"讲的是**通知对象自己的状态机**，
与"你调哪个包装函数"无关。

> 官方页用 `seL4_ARCH_Page_Map` 之类的宏名写示例（`ARCH` 会被平台头文件展开成
> `ARM`/`X86`），本仓库不跟着写：`seL4_ARM_*` 与 `seL4_X86_*` 都是构建时按 arch
> 生成的，树里搜不到（见 README"真实代码对齐哪一版"第 1 条）。

---

## 本章坑位清单（实测）

1. **把通知当同步 IPC**：通知是异步的位集合，发的人不排队。
2. **以为重复发送会累加计数**：`combine_idempotent`，同一个位发多少次都只算一次。
3. **以为发送顺序会影响结果**：`combine_commutes`。
4. **以为接收能挑位**：`receive_takes_the_whole_badge`——一次全取并清空，没有掩码。
5. **以为通知没有等待队列**：`WaitingNtfn "obj_ref list"` 就是队列，可以挂多个线程。
6. **把"绑定线程"当成"等待者"**：`ntfn_bound_tcb` 是单值，`WaitingNtfn` 是列表。
7. **以为重复绑定会报错**：`rebinding_just_moves_it`，绑定时两侧直接改写；
   报 `IllegalOperation` 的是**解绑一个没绑的线程**（`Decode_A.thy` 第 365 行）。
8. **把"没有消息"写成 `ntfn_obj n ≠ ActiveNtfn s`**：只对某一个 `s` 成立，
   要用 `no_message` 这样的谓词。
9. **以为非阻塞收失败会留着旧徽章**：`no_message_badge_is_zero`，寄存器被写成 0。
10. **以为 `assert (queue ≠ [])` 是多余的**：它靠的是井形性，
    `well_formed_send_is_never_asserted` 就是这句话的模型版。
11. **把 badge 当数字做算术**：它是位集合，用集合运算而不是 `+`。
12. **找 Reply 实现找错文件**：`seL4/src/object/reply.c`（不是 `endpoint.c`）。

---

上一章：[11 · IPC](11-ipc.md) ｜ 下一章：[13 · 线程控制块](13-tcb.md) ｜ 返回：[README](../README.md)
