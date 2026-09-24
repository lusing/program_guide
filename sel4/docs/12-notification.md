# 12 · 通知与 Reply

对应示例：`../examples/S12_notification.thy`

## 12.1 通知：一组二元信号量

通知对象（notification）里只有一个东西：**一个 badge 位集合**。
发信号就是把 badge 的位并进去，接收（poll）就是把当前位取走并清零。
这是 seL4 的异步信号机制，与同步的 IPC（第 11 章）互补。

真实对象在 `l4v/spec/abstract/Structures_A.thy` 的 `notification`，
C 侧 `seL4/src/object/notification.c`。

## 12.2 位运算模型

```text
theorem signal_is_monotone: ?pending \<subseteq> signal ?pending ?badge
```

```text
theorem
  signal_is_idempotent: signal (signal ?pending ?b) ?b = signal ?pending ?b
```

三条性质（还有一条可交换性）把"并集"讲清楚了：单调、幂等、可交换。
**重复发同一 badge 不会累加**——badge 是位，不是计数器。

```text
theorem
  poll_clears_those_bits:
    snd (poll ?pending ?badge) = ?pending - fst (poll ?pending ?badge)
```

`poll` 返回 `(取到的位, 剩余位)`，取走的位会被减掉。

## 12.3 绑定 TCB：通知只能有一个等待者

```text
theorem
  bind_twice_rejected: ntfn_bound ?n = Some ?t' \<Longrightarrow> bind_tcb ?t ?n = None
```

绑定是**一次性的**：已绑定的通知再绑返回 `None`（不是覆盖）。
这个"不可重绑"是通知能当"线程身份凭证"用的前提。

## 12.4 Reply 对象与一次性回答

```text
theorem
  reply_is_one_shot: consume_reply ?r = Some ?r' \<Longrightarrow> consume_reply ?r' = None
```

`seL4_Call` 会隐式创建一个 reply 能力，它只能用一次。
**"一次性"在类型上就体现为：成功消费一次之后必然失败**。
C 侧见 `seL4/src/object/reply.c`。

---

## 本章坑位清单（实测）

1. **把通知当同步 IPC**：通知是异步的位集合，不等人、不排队。
2. **以为重复发送会累加计数**：badge 是位，重复发是幂等的。
3. **以为发送顺序会影响结果**：`signal` 可交换。
4. **把 `poll` 的返回值顺序记反**：是 `(取到的位, 剩余位)`。
5. **以为 poll 不清零**：取走的位会被减掉。
6. **以为通知可以重绑定**：已绑定再绑返回 `None`。
7. **以为 reply 能力可以复用**：`reply_is_one_shot` 说明用过一次就废。
8. **把 badge 0 当有意义的 badge**：`0` 表示"没有 badge"，发送方身份不可辨认。
9. **在证明里把 badge 当数字做算术**：它是位集合，用集合运算而不是 `+`。
10. **找 Reply 实现找错文件**：`seL4/src/object/reply.c`（不是 `endpoint.c`）。

---

上一章：[11 · IPC](11-ipc.md) ｜ 下一章：[13 · 线程控制块](13-tcb.md) ｜ 返回：[README](../README.md)
