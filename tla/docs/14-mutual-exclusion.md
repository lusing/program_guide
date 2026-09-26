# 14 · 纯 TLA+ 写互斥：N 进程抢一把信号量

对应示例：`../examples/Ch14MutualExclusion.tla`

第 11 章用 PlusCal 写过互斥；这一章用**纯 TLA+** 重写，体会两种风格的差别，并掌握
TLA+ 描述并发的**标准范式**：`pc` 是"进程 → 阶段"的函数 + `\E p : ...` 表示"某个进程
做了某动作"。后面 15/16/17 章都复用这套写法。

本机实测（`Procs = {1,2,3}`）：`7 states generated, 4 distinct states found ...
No error has been found.`

## 规格

```tla
EXTENDS Integers, FiniteSets, TLC
CONSTANT Procs                       \* 进程 id 集合，.cfg 给 {1,2,3}

VARIABLES pc, sem
vars == <<pc, sem>>

Init ==
  /\ pc  = [p \in Procs |-> "idle"]   \* 所有进程从 idle 开始
  /\ sem = 1                          \* 二进制信号量：1=空闲，0=占用

Acquire(p) ==                         \* p 申请进临界区
  /\ pc[p] = "idle"
  /\ sem = 1
  /\ sem' = 0
  /\ pc' = [pc EXCEPT ![p] = "cs"]

Release(p) ==                         \* p 离开临界区
  /\ pc[p] = "cs"
  /\ sem' = 1
  /\ pc' = [pc EXCEPT ![p] = "idle"]

ProcStep(p) == Acquire(p) \/ Release(p)
Next == \E p \in Procs : ProcStep(p)  \* 一步 = 任选一个进程行动
Spec == Init /\ [][Next]_vars
```

并发范式的精髓全在 `Next == \E p \in Procs : ProcStep(p)`：

- `pc` 是一个**函数** `Procs -> {"idle","cs"}`，记录每个进程在哪。
- `[pc EXCEPT ![p] = "cs"]` 只改 `p` 这一个进程的 pc，其余不变（第 03 章的 `EXCEPT`）。
- `\E p \in Procs : ...` 表示"**存在某个进程** p 做了它的动作"——到底哪个 p，由 TLC
  穷举所有可能。**并发 = 每一步任选一个进程行动**，这就是 nondeterminism 的来源。

> 命名坑：不能同时定义 `Next(p)` 和 `Next`（TLC 报 `Operator Next already defined`）。
> 所以带参的那个叫 `ProcStep(p)`。

## 性质

```tla
TypeOK ==
  /\ pc \in [Procs -> {"idle", "cs"}]
  /\ sem \in {0, 1}

MutEx == Cardinality({p \in Procs : pc[p] = "cs"}) <= 1   \* 至多一个在临界区

SemConsistent == (sem = 0) <=>
                 (Cardinality({p \in Procs : pc[p] = "cs"}) = 1)
```

- `MutEx` 是**互斥**：处于临界区的进程数 ≤ 1。这是安全性（第 07 章），无需公平性。
- `SemConsistent` 把信号量和临界区绑起来：`sem=0` 当且仅当恰有一个进程在临界区。
  它解释了"为什么互斥成立"——因为 `Acquire` 原子地把 `sem` 从 1 置 0，第二个进程的
  `Acquire` 因 `sem = 1` 守卫不满足而被禁用。

`.cfg`：

```text
INIT Init
NEXT Next
CONSTANT Procs = {1, 2, 3}
INVARIANT TypeOK
INVARIANT MutEx
INVARIANT SemConsistent
```

TLC 穷举 3 个进程的所有调度交错（4 个不同状态：谁在临界区 / 都没在），确认互斥永不
被打破。

## 为什么这里 `Acquire` 是原子的

`Acquire(p)` 把"检查 `sem=1`"和"置 `sem'=0`"写在**同一个动作**里。在 TLA+ 中，一个
动作就是一步、不可分割。所以两个进程不可能"都看到 sem=1、都去占用"——这正是第 11 章
PlusCal 里 `await (lock=FALSE); lock := TRUE;` 放在同一标签下要表达的同一件事。

**互斥的正确性 = "检查并占用"这一步的原子性。** 第 17 章会演示：一旦把"检查/读"和
"占用/写"拆成两步（中间能被插队），互斥/守恒立刻就被 TLC 抓出反例。

## 想证"不会饿死"怎么办

本章只证了安全性（互斥）。"每个想进临界区的进程终将进入"是**活性**，需要：

1. 给 `Spec` 加公平性 `WF_vars(Next)` 或更强的 `SF`；
2. 用 `PROPERTY <>(...)` 或 `[]<>(pc[p]="cs")` 表述。

而且如第 11 章所述，二进制信号量本身**不防饿死**（某进程可能被反复插队）。要防饿死得
换更公平的算法（如票号算法）。这留作练习——重点是先体会：**安全性易证且最常用，活性
需要公平性且更微妙**。

---
上一章：[13 · 水壶问题](13-diehard.md) ｜ 下一章：[15 · 银行转账](15-bank-transfer.md) ｜ 返回：[README](../README.md)
