# 17 · 竞态条件：亲眼看见"丢更新"

对应示例：`../examples/Ch17RaceCondition.tla`

并发 bug 的头号经典：两个进程各自对共享计数器做"读-改-写"，但读和写被拆成**两个独立
步骤**。若两个进程都先读、再各自写回，后写的会覆盖先写的，导致计数器少加一次
（**lost update**，丢更新）。本章让 TLC 把这条触发竞态的交错**打印出来**，再用原子动作
把它修好。

> 默认 `.cfg` 检查**有 bug 的** `SpecBuggy`，不变式 `cnt = writes` 会被证伪——这是
> "演示错误"示例，`run-all.sh` 期望 TLC **报违反**（抓到才算通过）。

## 有 bug 的版本：读-改-写拆成两步

```tla
Procs == {1, 2}
VARIABLES pc, cnt, r, writes
\*   pc[p]   进程 p 的阶段："rd"（待读）、"wr"（待写）、"done"
\*   cnt     共享计数器
\*   r[p]    进程 p「读」到的 cnt 暂存值
\*   writes  实际发生的写次数（对照基准）

Init == /\ pc = [p \in Procs |-> "rd"] /\ cnt = 0
        /\ r = [p \in Procs |-> 0] /\ writes = 0

Read(p) ==                       \* 第一步：把当前 cnt 读进 r[p]
  /\ pc[p] = "rd"
  /\ r'  = [r EXCEPT ![p] = cnt]
  /\ pc' = [pc EXCEPT ![p] = "wr"]
  /\ UNCHANGED <<cnt, writes>>

Write(p) ==                      \* 第二步：基于「之前读到的」r[p] 写回
  /\ pc[p] = "wr"
  /\ cnt'    = r[p] + 1
  /\ writes' = writes + 1
  /\ pc'     = [pc EXCEPT ![p] = "done"]
  /\ UNCHANGED r

NextBuggy == \E p \in Procs : Read(p) \/ Write(p)
Consistent == cnt = writes       \* 期望：计数器值 = 写次数
```

`Read` 和 `Write` 之间隔着标签（是两个动作），所以**别的进程能在这两步之间插队**。
这就是竞态的温床。

## TLC 抓到的反例（本机实测原文）

```text
Error: Invariant Consistent is violated.
State 1: <Initial>  cnt=0  r=<<0,0>>  pc=<<"rd","rd">>  writes=0
State 2: <Read>     cnt=0  r=<<0,0>>  pc=<<"wr","rd">>  writes=0
State 3: <Read>     cnt=0  r=<<0,0>>  pc=<<"wr","wr">>  writes=0
State 4: <Write>    cnt=1  r=<<0,0>>  pc=<<"done","wr">> writes=1
State 5: <Write>    cnt=1  r=<<0,0>>  pc=<<"done","done">> writes=2
```

逐帧读这条死法：

- State 2、3：**两个进程都先 Read**，各自把 `cnt=0` 读进自己的 `r`（`r=<<0,0>>`）。
  此刻没人写，`cnt` 还是 0。
- State 4：进程 1 Write，`cnt = r[1]+1 = 0+1 = 1`，`writes=1`。一致。
- State 5：进程 2 Write，`cnt = r[2]+1 = 0+1 = 1`（它读到的还是**旧的 0**！），
  `writes=2`。于是 **`cnt=1` 但 `writes=2`** —— 进程 2 的自增把进程 1 的结果覆盖了，
  丢了一次更新。`Consistent`（`cnt = writes`）被打破。

两次自增，结果只加了 1。这就是无数真实系统里"计数器对不上""库存超卖""余额错乱"的
根因。TLC 用 5 步把它钉死。

## 修复：把读-改-写并成一个原子步

```tla
Incr(p) ==                   \* 读-改-写合成一个不可分割的动作
  /\ pc[p] = "rd"
  /\ cnt'    = cnt + 1       \* 直接基于「当前」cnt 自增，不留中间暂存
  /\ writes' = writes + 1
  /\ pc'     = [pc EXCEPT ![p] = "done"]
  /\ UNCHANGED r

NextFixed == \E p \in Procs : Incr(p)
SpecBuggy == Init /\ [][NextBuggy \/ Idle]_vars
SpecFixed == Init /\ [][NextFixed \/ Idle]_vars
```

（`Idle` 在两进程都 `done` 后原地踏步，避免 TLC 报死锁。）

把 `.cfg` 换成检查修复版：

```text
SPECIFICATION SpecFixed
INVARIANT Consistent
```

本机实测：

```text
Model checking completed. No error has been found.
6 states generated, 4 distinct states found, 0 states left on queue.
```

`cnt = writes` 恒成立——因为 `Incr` 把"读当前值"和"写回 +1"放在**同一个动作**里，
中间没有标签、不给别的进程插队的机会。这正是第 14 章 `Acquire` 原子占用信号量、第 11
章 `await; lock:=TRUE` 同标签的同一个道理：

> **并发正确性 = 把"检查 + 修改"做成原子的一步。** 一旦中间能被插队，TLC（和现实）
> 就会找到那条致命的交错。

## 对照现实

修复版相当于真实代码里的：用锁把 `read-modify-write` 整段包住、或用 CPU 的原子
CAS 指令、或数据库的单条 `UPDATE ... SET cnt = cnt + 1`。bug 版相当于：

```python
tmp = shared          # 读
shared = tmp + 1      # 改 + 写  —— 两步之间被另一个线程插队，就丢更新
```

TLA+ 让你在**写实现之前**就看见这个 bug。

---
上一章：[16 · 生产者-消费者](16-producer-consumer.md) ｜ 下一章：[18 · 速查表](18-cheatsheet.md) ｜ 返回：[README](../README.md)
