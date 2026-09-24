# 14 · 调度

对应示例：`../examples/S14_schedule.thy`

## 14.1 调度：优先级 + 轮转 + 域

第 07 章说结果集合是因为有非确定性，而非确定性的最大来源就是**调度器**：
下一个跑谁，由优先级、域（domain）、时间片共同决定，而这些在抽象规范里是"任选一个合法选择"。

真实代码：`l4v/spec/abstract/Schedule_A.thy` 的 `choose_thread` /
`switch_to_thread` / `next_domain` / `switch_to_idle_thread`，
C 侧 `seL4/src/kernel/thread.c`。

## 14.2 入队与出队

```text
theorem enqueue_adds: ?t \<in> set (enqueue ?p ?t ?qs ?p)
```

按优先级分队列（`nat ⇒ nat list`）。入队从尾部加、出队按 FIFO。
注意"同一个线程不能在队列里出现两次"是调度不变式的一部分。

## 14.3 选线程：取最高优先级

```text
theorem no_queues_means_idle: choose_thread empty_queues ?ps = SwitchToIdle
```

```text
theorem
  higher_priority_wins:
    choose_thread (empty_queues(1 := [?lo], 9 := [?hi])) [1, 9] =
    SwitchTo ?hi
```

没有可运行线程就切到 idle；有多个队列时取**优先级最高**的那个。

## 14.4 域：粗粒度的时间隔离

```text
theorem
  next_domain_wraps:
    ds_index ?s + 1 = length (ds_list ?s) \<Longrightarrow> ds_index (next_domain ?s) = 0
```

域是比优先级更硬的一层隔离：一个域的时间片用完了才轮到下一个域。
**域调度是 seL4 时间隔离的基础**，第 22 章的非干扰证明会要求
"策略不允许的调度不发生"。

## 14.5 idle 线程不是普通线程

```text
theorem idle_switch_is_idle: switch SwitchToIdle = TargetIdle
```

idle 线程没有上下文可保存，也不是一个能被调度的"任务"，
它是"实在没人可跑时的兜底"。

---

## 本章坑位清单（实测）

1. **以为调度是确定性的**：抽象规范里是"任选一个合法选择"，证明必须对**所有**选择成立。
2. **把"选最高优先级"写成"选第一个非空队列"**：取决于优先级列表的遍历方向，实测是高的赢。
3. **忘了"没有可运行线程就切 idle"**：`choose_thread` 必须总有返回值。
4. **同一线程重复入队**：会破坏"队列里每个线程至多一次"的不变式。
5. **域索引的取模漏掉**：`next_domain` 用 `mod`，越界时绕回。
6. **把域与优先级混为一谈**：域先于优先级。
7. **以为 `switch_to_idle_thread` 与切线程走同一条路**：idle 线程没有上下文可保存。
8. **在证明里展开队列为列表**：用 `set` 成员关系而不是列表相等。
9. **忽略了调度本身也要保持不变式**：`l4v/proof/invariant-abstract/DetSchedInvs_AI.thy` 专门处理。
10. **找调度实现找错文件**：C 侧在 `seL4/src/kernel/thread.c`（不在 `src/object/`）。

---

上一章：[13 · 线程控制块](13-tcb.md) ｜ 下一章：[15 · 内存再类型化](15-retype.md) ｜ 返回：[README](../README.md)
