# 11 · IPC

对应示例：`../examples/S11_ipc.thy`

## 11.1 端点：同步的汇合点

seL4 的端点（endpoint）是**同步 IPC** 的原语：发送方遇到接收方就交接，
否则自己排队阻塞；接收方同理。端点只有三种状态：`IdleEP`、
`SendEP [队列]`、`RecvEP [队列]`（`l4v/spec/abstract/Structures_A.thy`）。

真实代码：`l4v/spec/abstract/Ipc_A.thy` 的 `send_ipc` / `receive_ipc` /
`do_ipc_transfer`，C 侧 `seL4/src/object/endpoint.c`。

## 11.2 发送：有接收者就交接，没有就排队

```text
theorem send_to_idle_blocks: send_ipc True IdleEP ?t = (SendEP [?t], Queued)
```

```text
theorem
  nonblocking_send_to_idle_drops:
    send_ipc False IdleEP ?t = (IdleEP, Dropped)
```

阻塞标志（第一个 `bool`）只影响"没人接怎么办"：阻塞就排队，非阻塞就丢弃。
**消息被丢弃是正常语义，不是错误**。

## 11.3 接收：对称的另一半

接收是发送的镜像：有发送者在等就交接，否则排队；非阻塞时返回 `Dropped`。

## 11.4 井形性在状态转移下保持

```text
theorem idle_is_well_formed: ep_well_formed IdleEP
```

```text
theorem empty_send_queue_not_well_formed: \<not> ep_well_formed (SendEP [])
```

```text
theorem
  send_preserves_well_formed:
    ep_well_formed ?ep \<Longrightarrow> ep_well_formed (fst (send_ipc ?b ?ep ?t))
```

空队列不合法——队列空了就该变成 `IdleEP`。
这类"表示唯一性"的不变式在 seL4 里到处都是：**同一个语义状态只允许一种表示**。
最后一条是不变式保持的最小范例，第 17 章会把它推广到整个内核状态。

## 11.5 badge：区分发送方，但不决定能不能发

一条常见误传要在这里纠正：**徽章为 0 并不阻止发送**。
发送的闸门是**权利位**——C 侧端点能力里的 `capCanSend`
（`seL4/include/object/structures_32.bf` 第 28 行的
`endpoint_cap(capEPBadge, capCanGrantReply, capCanGrant, capCanSend, …)`），
Isabelle 侧就是 `AllowSend`，定义在 `l4v/spec/abstract/CapRights_A.thy` 第 22 行，
内容只有一行 `"AllowSend ≡ AllowWrite"`（第 03 章"权利是同义词"的典型例子）。
解码器原文（`l4v/spec/abstract/Decode_A.thy` 第 632 行起）：

<!-- 源码块：l4v/spec/abstract/Decode_A.thy:632-635 -->

```text
    EndpointCap ptr badge rights \<Rightarrow>
      if AllowSend \<in> rights then
        returnOk $ InvokeEndpoint ptr badge (AllowGrant \<in> rights) (AllowGrantReply \<in> rights)
      else throwError $ InvalidCapability 0
```

0 号徽章能不能发，实测：

```text
theorem zero_badge_still_sends: can_send (EndpointCap ?ptr 0 {AllowSend})
```

```text
theorem
  no_right_blocks_sending:
    AllowWrite \<notin> ?R \<Longrightarrow> \<not> can_send (EndpointCap ?ptr ?b ?R)
```

第二条说明真正关住发送的是权利，不是徽章。

徽章真正触发的是另一件事：`seL4_CNode_CancelBadgedSends`。
它的解码闸是 `has_cancel_send_rights`
（`l4v/spec/abstract/CSpace_A.thy` 第 787 行），条件苛刻——
权利集必须等于全集；执行那一支则是
`CancelBadgedSendsCall (EndpointCap ep b R) ⇒ without_preemption $ when (b ≠ 0) $ cancel_badged_sends ep b`
（同文件第 838 行）。换句话说：**只有"全权利 + 有徽章"的那一份能力
能取消别人排队的发送**。

```text
theorem
  unbadged_full_cap_cancels_nothing:
    \<not> cancels_pending_sends (EndpointCap ?ptr 0 UNIV)
```

```text
theorem
  badged_full_cap_cancels: cancels_pending_sends (EndpointCap ?ptr 7 UNIV)
```

```text
theorem
  reduced_rights_cannot_cancel:
    ?R \<noteq> UNIV \<Longrightarrow> \<not> cancels_pending_sends (EndpointCap ?ptr ?b ?R)
```

取徽章的工具函数是 `cap_ep_badge`（`l4v/spec/abstract/Structures_A.thy` 第 141 行），
mint 时把徽章打上去的是 `update_cap_data`（`l4v/spec/abstract/CSpace_A.thy` 第 122 行）。
通知（第 12 章）与 IPC 的徽章机制共同回答"消息是谁发的"。

---

## 官方教程对照

官方 [ipc](https://docs.sel4.systems/Tutorials/ipc.html) 页（抓取日期 2026-09-25）
把端点讲成"排队线程的汇合点"、badge 讲成"区分发送者"、
并说快路径要求"不带能力 + 数据小"。三条都对，
但它给的 API 清单是 **master 内核那一套**，而且没讲任何一位宽度。下面逐条钉住。

**1. 系统调用原型有两份，差别不只是多一个参数。**
`seL4/libsel4/include/sel4/syscalls.h:18--22` 按 `CONFIG_KERNEL_MCS`
二选一（非 MCS 用 `syscalls_master.h`、MCS 用 `syscalls_mcs.h`），
所以"哪个调用存在"本身是配置决定的。实测差异（行号是各自文件里的）：

| 调用 | master | MCS |
|---|---|---|
| `seL4_Send` | `seL4/libsel4/include/sel4/syscalls_master.h:27` | 两边同形 |
| `seL4_Recv` | `(src, sender)`：`seL4/libsel4/include/sel4/syscalls_master.h:51` | 多一个 `reply`：`seL4/libsel4/include/sel4/syscalls_mcs.h:52` |
| `seL4_Wait` | 返回 `void`：`seL4/libsel4/include/sel4/syscalls_master.h:200` | 返回 `seL4_MessageInfo_t`：`seL4/libsel4/include/sel4/syscalls_mcs.h:233` |
| `seL4_Reply` | 存在：`seL4/libsel4/include/sel4/syscalls_master.h:86` | **没有这个调用** |
| `seL4_NBSendRecv` | 没有 | 存在：`seL4/libsel4/include/sel4/syscalls_mcs.h:168` |
| `seL4_NBWait` | 没有 | 存在：`seL4/libsel4/include/sel4/syscalls_mcs.h:259` |

官方 ipc 页列的七个调用（`seL4_Send`、`seL4_NBSend`、`seL4_Recv`、`seL4_NBRecv`、
`seL4_Call`、`seL4_Reply`、`seL4_ReplyRecv`）**一个都不提 reply 参数**，
在 MCS 内核上全部要改写。`seL4_Reply` 在 MCS 下不存在这件事，
就是第 12 章"reply 对象取代了隐式回答"的直接后果。

**2. badge 和 label 是同一段位。** `seL4_MessageInfo`
（`seL4/libsel4/mode_include/32/sel4/shared_types.bf:11--16`）只有四个字段：
`label 20` + `capsUnwrapped 3` + `extraCaps 2` + `length 7` = 32 位；
64 位只把 label 加成 52（`seL4/libsel4/mode_include/64/sel4/shared_types.bf`）。
**length 永远只占低 7 位**（所以 `seL4_MsgMaxLength = 120` 这个上限是位宽给的，
不是缓冲区给的），`extraCaps` 只有 2 位（最多 3 个能力，见第 10 章）。
本章 11.5 说"badge 只是标签、不决定能不能发"——在 C 里它的实现就是
"发不出去时那 20/52 位照抄，收发两端各自解释"。

**3. 真正管住 badge 的是能力里的位宽。** `capEPBadge`
在 32 位架构上只有 28 位（`seL4/include/object/structures_32.bf:36`），
64 位才是整字（同一份位域的 64 位版本里 `capEPBadge` 占满 64 位）。
`capNtfnBadge` 同理，32 位下也是 28 位
（`seL4/include/object/structures_32.bf:41`）。
**官方页里"badge 用来区分发送者"没有告诉你上限**：
在 32 位平台上第 29 位起是拿不到的，而且端点能力的字里已经有四个权利位
和一个对象指针在争这一段空间（第 02 章第 4 条）。

**4. "快路径要小数据、不带能力"在三个 arch 里是三种写法。**
判据函数 `fastpath_mi_check`：x86-32 写成
`(msgInfo & MASK(seL4_MsgLengthBits + seL4_MsgExtraCapBits)) > seL4_FastMessageRegisters`，
见 `fastpath_mi_check` 在 `seL4/include/arch/x86/arch/32/mode/fastpath/fastpath.h:96--99`；
ARM64 把常数写死成 `> 4`，见 `fastpath_mi_check` 在
`seL4/include/arch/arm/arch/64/mode/fastpath/fastpath.h:114--116`，
并且上一行放了一个
`compile_assert(n_msgRegisters_eq_4, n_msgRegisters == 4)`；
ARM32 用 `(x + 3) & ~MASK(3)` 的技巧，见
`fastpath_mi_check` 在 `seL4/include/arch/arm/arch/32/mode/fastpath/fastpath.h:92--96`。
三种写法都只看**低 9 位**（length 7 位 + extraCaps 2 位拼在一起）：
`extraCaps` 非 0 时这个值必然 > 4，所以"不带能力"这一条根本不需要单独判——
**这是一次把两个条件折成一次位运算的优化**。arm32 文件里那段注释
（同一个函数头上，`n_msgRegisters_eq_4` 往上的几行）
把这件事讲得很明白，值得读原文。

**5. 超过寄存器数量的 MR 走缓冲区，长度会被改写。** `copyMRs`
（`seL4/src/object/tcb.c:418`）先 "Copy inline words" 到 `n_msgRegisters`，
其余的从 `sendBuf` 搬；收端最终看到的 tag 里的 length
是**实际传了几个**：`seL4_MessageInfo_set_length` 回填
（`seL4/src/kernel/thread.c:221--226`）。所以"我发了 8 个 MR"在另一头可能是 4——
官方页教 `seL4_GetMR(i)` 时没有提醒这一条，本章 11.4 的良构性讨论才有。

> 与本章模型的差距：l4v 的 IPC 规范里"消息"只有 badge 和 extra caps 两件事，
> MR 内容整体被抽象掉（第 19 章会说 C 侧怎么表示 IPC 缓冲区）。
> 因此任何依赖"第 i 个 MR 是什么"的论证在规范层是不存在的，
> 别把 C 的 MR 语义当作被证明过的性质。

---

## 本章坑位清单（实测）

1. **把 `SendEP []` 当合法状态**：井形性明确排除空队列。
2. **以为非阻塞发送失败会报错**：是 `Dropped`，消息被丢弃，调用正常返回。
3. **以为队列不是 FIFO**：实测取队首，其余保持。
4. **把 `Queued` 当错误**：它是"已排队等待"的正常结果。
5. **漏掉"交接后端点回到 Idle"**：结果是 `IdleEP`，不是保持 `RecvEP`。
6. **发送方遇到发送方时以为会交接**：同向不交接，继续排队。
7. **把 IPC 当异步**：端点是同步原语，异步靠通知。
8. **绕开 `ep_well_formed` 的定义**：它是个按端点分情况的 `case` 谓词，
   `simp add: ep_well_formed_def` 直接展开；两条"保持"引理还需要
   `split: endpoint.splits list.splits` 把嵌套的 `case` 也拆开。
9. **忘了 `fst`**：`send_ipc` 返回 `(端点, 结果)` 二元组。
10. **把"徽章为 0"当成不能发送**：闸门是权利位 `AllowSend`（= `AllowWrite`），
    实测 `zero_badge_still_sends`——0 号徽章照样发。
11. **以为有徽章就能取消别人排队的发送**：还要权利集等于全集
    （`has_cancel_send_rights`，`CSpace_A.thy` 第 787 行），
    实测 `reduced_rights_cannot_cancel`。
12. **把 `CancelBadgedSends` 在 0 号徽章时的"什么都不做"当错误**：
    规范里那是 `when (b ≠ 0)` 短路，调用本身正常返回。

---

上一章：[10 · 解码器](10-decode.md) ｜ 下一章：[12 · 通知与 Reply](12-notification.md) ｜ 返回：[README](../README.md)
