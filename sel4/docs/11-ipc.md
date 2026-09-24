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

## 11.5 badge：区分发送方

```text
theorem unbadged_cannot_send: \<not> can_send 0
```

badge 是"发送者身份"的凭证，`0` 表示没有。
通知（第 12 章）与 IPC 的 badge 机制共同回答"消息是谁发的"。

---

## 本章坑位清单（实测）

1. **把 `SendEP []` 当合法状态**：井形性明确排除空队列。
2. **以为非阻塞发送失败会报错**：是 `Dropped`，消息被丢弃，调用正常返回。
3. **以为队列不是 FIFO**：实测取队首，其余保持。
4. **把 `Queued` 当错误**：它是"已排队等待"的正常结果。
5. **漏掉"交接后端点回到 Idle"**：结果是 `IdleEP`，不是保持 `RecvEP`。
6. **发送方遇到发送方时以为会交接**：同向不交接，继续排队。
7. **把 IPC 当异步**：端点是同步原语，异步靠通知。
8. **在证明里展开 `ep_well_formed`**：它是按端点类型分情况的谓词，用 `cases` 而不是 `simp`。
9. **忘了 `fst`**：`send_ipc` 返回 `(端点, 结果)` 二元组。
10. **badge 为 0 时以为还能发**：`unbadged_cannot_send` 说明不能。

---

上一章：[10 · 解码器](10-decode.md) ｜ 下一章：[12 · 通知与 Reply](12-notification.md) ｜ 返回：[README](../README.md)
