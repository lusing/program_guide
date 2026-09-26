--------------------------- MODULE Ch17RaceCondition ---------------------------
\* 第 17 章：竞态条件——亲眼看见「丢更新」，再把它修好。
\* 这是并发 bug 的头号经典：两个进程各自对共享计数器做「读-改-写」，
\* 但读和写被拆成**两个独立步骤**。若两个进程都先读、再各自写回，
\* 后写的会覆盖先写的，导致计数器少加一次（lost update）。
\*
\* 本章用「演示错误」模式：默认 cfg 检查**有 bug 的** SpecBuggy，
\* 不变式 cnt = writes 会被 TLC 证伪，反例就是那条触发竞态的交错。
\* 文件里同时给出修复版 SpecFixed（把读-改-写并成一个原子步），docs 里演示切换。

EXTENDS Integers, FiniteSets, TLC

Procs == {1, 2}

\* 状态变量：
\*   pc[p]    进程 p 的阶段："rd"（待读）、"wr"（待写）、"done"（完成）
\*   cnt      共享计数器
\*   r[p]     进程 p 「读」到的 cnt 暂存值
\*   writes   实际发生的写次数（用作对照基准）
VARIABLES pc, cnt, r, writes
vars == <<pc, cnt, r, writes>>

Init ==
  /\ pc     = [p \in Procs |-> "rd"]
  /\ cnt    = 0
  /\ r      = [p \in Procs |-> 0]
  /\ writes = 0

\* ❌ 有 bug：把「读-改-写」拆成两步。
Read(p) ==
  /\ pc[p] = "rd"
  /\ r'  = [r EXCEPT ![p] = cnt]          \* 第一步：把当前 cnt 读进 r[p]
  /\ pc' = [pc EXCEPT ![p] = "wr"]
  /\ UNCHANGED <<cnt, writes>>

Write(p) ==
  /\ pc[p] = "wr"
  /\ cnt'    = r[p] + 1                   \* 第二步：基于「之前读到的」r[p] 写回
  /\ writes' = writes + 1
  /\ pc'     = [pc EXCEPT ![p] = "done"]
  /\ UNCHANGED r

NextBuggy == \E p \in Procs : Read(p) \/ Write(p)

\* ✅ 修复：读-改-写合成一个**原子**动作，中间不给别的进程插队的机会。
Incr(p) ==
  /\ pc[p] = "rd"
  /\ cnt'    = cnt + 1                    \* 直接基于「当前」cnt 自增
  /\ writes' = writes + 1
  /\ pc'     = [pc EXCEPT ![p] = "done"]
  /\ UNCHANGED r

NextFixed == \E p \in Procs : Incr(p)

\* 两个进程都完成后原地踏步，避免 TLC 报死锁。
Idle == /\ \A p \in Procs : pc[p] = "done"
        /\ UNCHANGED vars

SpecBuggy == Init /\ [][NextBuggy \/ Idle]_vars
SpecFixed == Init /\ [][NextFixed \/ Idle]_vars

\* 期望的不变式：计数器值 = 实际写次数。修复版恒成立；bug 版会被竞态打破。
Consistent == cnt = writes
=============================================================================
\* 默认 cfg 检查 bug 版（run-all.sh 期望 TLC 报违反）：
\*   SPECIFICATION SpecBuggy
\*   INVARIANT Consistent
\* TLC 会打印一条反例：两个进程都先 Read（各读到 cnt=0），再先后 Write，
\*   结果 writes=2 但 cnt=1 —— 丢了一次更新。
\*
\* 想看修复版通过，把 cfg 改成：
\*   SPECIFICATION SpecFixed
\*   INVARIANT Consistent
\* 再跑就会得到 "No error has been found"。
