# 13 · 线程控制块

对应示例：`../examples/S13_tcb.thy`

## 13.1 TCB：内核眼里的"线程"

线程控制块（TCB）是 seL4 里最"重"的对象：线程状态、优先级、
CSpace 根（ctable）、VSpace 根、IPC 缓冲区、时间片、绑定的通知……

真实定义见 `l4v/spec/abstract/Structures_A.thy` 的 `tcb` record，
操作在 `l4v/spec/abstract/Tcb_A.thy` 与 `TcbAcc_A.thy`，C 侧 `seL4/src/object/tcb.c`。

## 13.2 可运行性

```text
theorem running_is_runnable: runnable Running
```

```text
theorem blocked_on_send_is_not_runnable: \<not> runnable (BlockedOnSend ?p)
```

`runnable` 是一个**谓词**，不是状态构造子：`Running` 与 `Restart` 都算可运行，
`BlockedOnSend` / `BlockedOnReceive` / `Inactive` / `IdleThreadState` 不算。
调度器（第 14 章）只从 `runnable` 的线程里挑。

## 13.3 改一个字段，别的字段不动

```text
theorem
  set_state_idempotent:
    set_thread_state ?ts (set_thread_state ?ts ?t) = set_thread_state ?ts ?t
```

这类"改了一处、别处不动"的定理是 record 更新的标配。
在 seL4 的证明里它们通常不用手写——`l4v/lib/Crunch.thy` 与
`l4v/lib/AddUpdSimps.thy` 会批量生成。

幂等性看着显然，但在"连续两次设置状态"的调用序列里是必需的。

## 13.4 挂起与恢复

```text
theorem suspend_makes_inactive: tcb_state (suspend ?t) = Inactive
```

```text
theorem suspend_then_resume_state: tcb_state (resume (suspend ?t)) = Restart
```

注意第二条：挂起再恢复，状态是 **`Restart`** 而不是 `Running`。
`Restart` 表示"从头开始跑"（要重新初始化寄存器上下文），
这和被中断后继续跑（`Running`）是两回事。

## 13.5 TCB 里的 CSpace 根

```text
theorem ctable_is_slot_zero: tcb_cnode_index 0 = 0
```

每个 TCB 自带一个 CNode，线程的 CSpace 根就在这个 CNode 的 0 号槽。
第 04 章的 `lookup_slot_for_thread` 正是从这里出发解析能力地址的。

---

## 本章坑位清单（实测）

1. **把 `runnable` 当状态构造子**：它是谓词，`Running` 与 `Restart` 都满足。
2. **以为挂起再恢复回到 `Running`**：实测是 `Restart`。
3. **改状态时顺手改了别的字段**：要用"只动一处"的定理把无关字段钉住。
4. **把 `Inactive` 与 `IdleThreadState` 混为一谈**：一个是用户线程被挂起，一个是内核空闲线程。
5. **以为 `set_thread_state` 幂等是显然的**：连续设置序列里必须显式用这条定理。
6. **忘了 ctable 是 0 号槽**：解析线程的 CSpace 要从 `tcb_cnode_index 0` 出发。
7. **在证明里展开整个 `tcb` record**：字段太多，用选择器引理代替展开。
8. **把优先级当无界整数**：真实内核里优先级有范围，越界设置会被拒绝。
9. **以为 TCB 可以被任意线程修改**：修改 TCB 需要持有该 TCB 的能力，权利检查在解码层。
10. **找 TCB 实现找错文件**：C 侧是 `seL4/src/object/tcb.c`，规范侧是 `Tcb_A.thy`（访问器在 `TcbAcc_A.thy`）。

---

上一章：[12 · 通知与 Reply](12-notification.md) ｜ 下一章：[14 · 调度](14-schedule.md) ｜ 返回：[README](../README.md)
