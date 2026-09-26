-------------------------- MODULE Ch14MutualExclusion --------------------------
\* 第 14 章：纯 TLA+ 写并发——N 个进程抢一把二进制信号量，证明互斥。
\* 第 11 章用 PlusCal 写过互斥；这一章用**纯 TLA+** 重写，体会两种风格的差别：
\*   · PlusCal：你描述「每个进程怎么一步步走」，工具翻译成动作。
\*   · 纯 TLA+：你直接描述「系统允许哪些状态跳变」，用 \E p : ... 表示
\*     「某个进程做了某动作」。并发 = 每步任选一个进程行动。
\*
\* 这套写法（pc 是「进程 -> 所处阶段」的函数 + \E 选一个进程）是 TLA+ 描述
\* 并发系统的标准范式，后面 Ch15/16/17 都会复用。

EXTENDS Integers, FiniteSets, TLC

CONSTANT Procs                       \* 进程 id 集合，.cfg 里给 {1,2,3}

\* 状态变量：
\*   pc[p]  进程 p 当前所处阶段："idle"（空闲）或 "cs"（临界区）
\*   sem    二进制信号量：1 = 空闲可用，0 = 被占用
VARIABLES pc, sem
vars == <<pc, sem>>

Init ==
  /\ pc  = [p \in Procs |-> "idle"]   \* 所有进程都从 idle 开始
  /\ sem = 1

\* 进程 p 申请进入临界区：只有 p 在 idle 且信号量可用时才行（原子地占用信号量）。
Acquire(p) ==
  /\ pc[p] = "idle"
  /\ sem = 1
  /\ sem' = 0
  /\ pc' = [pc EXCEPT ![p] = "cs"]

\* 进程 p 离开临界区：释放信号量，回到 idle。
Release(p) ==
  /\ pc[p] = "cs"
  /\ sem' = 1
  /\ pc' = [pc EXCEPT ![p] = "idle"]

\* 一步 = 任选一个进程，执行它的 Acquire 或 Release。
\* \E p \in Procs 正是「并发 nondeterminism」的来源：哪个进程动、做什么，都不定。
ProcStep(p) == Acquire(p) \/ Release(p)
Next == \E p \in Procs : ProcStep(p)

Spec == Init /\ [][Next]_vars

\* --- 性质 -----------------------------------------------------------
TypeOK ==
  /\ pc \in [Procs -> {"idle", "cs"}]
  /\ sem \in {0, 1}

\* 互斥（安全性）：任意时刻，处于临界区的进程数 <= 1。
MutEx == Cardinality({p \in Procs : pc[p] = "cs"}) <= 1

\* 信号量与临界区一致：sem=0 当且仅当恰有一个进程在临界区。
SemConsistent == (sem = 0) <=> (Cardinality({p \in Procs : pc[p] = "cs"}) = 1)
=============================================================================
