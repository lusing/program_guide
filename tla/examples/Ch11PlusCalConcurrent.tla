-------------------------- MODULE Ch11PlusCalConcurrent --------------------------
\* 第 11 章：PlusCal 并发——process、await、原子步与互斥。
\*
\* 并发的关键是 PlusCal 的 process：声明多个进程，TLC 会以**所有可能的交错**
\* 来调度它们。下面用一把「锁」实现两个进程对临界区的互斥访问，并让 TLC 证明
\* 「任意时刻至多一个进程在临界区」永远成立。
\*
\* 两个 PlusCal 关键概念：
\*   · 标签（label，如 a: b: c:）划定**原子步**边界：同一标签下、到下一个标签
\*     之前的所有语句，作为一个不可分割的步骤执行。这是并发正确性的命门。
\*   · await P（等价于 wait P）：阻塞本进程，直到谓词 P 为真才继续。
\*   · self：当前进程自己的 id。

EXTENDS Integers, FiniteSets, TLC

\* 算法体：一把布尔锁 lock；两个进程 P 各自循环——
\*   在标签 b 处「await 锁空闲，然后上锁」是**同一原子步**（test-and-set），
\*   所以两个进程不可能同时拿到锁；进入临界区把 inCS 置真，出来再释放锁。
\* 语法坑：per-process 的 variable 声明要写在 process(...) 与 body 花括号**之间**，
\*   不能放进花括号内部，否则 pcal.trans 报 "Expected := but found ;"。
(* --fair algorithm Mutex {
  variables lock = FALSE;
  process (P \in {1, 2})
  variable inCS = FALSE;
  {
    a: while (TRUE) {
         b: await (lock = FALSE);
            lock := TRUE;
         c: inCS := TRUE;
         d: inCS := FALSE;
            lock := FALSE;
       }
  }
} *)

\* 翻译后 inCS 变成「以进程 id 为下标」的数组：inCS[i]。ProcSet = {1,2}。
\* 互斥（安全性）：不存在两个不同进程同时 inCS 为真。
MutEx ==
  \A i \in ProcSet : \A j \in ProcSet :
    (i # j) => ~(inCS[i] /\ inCS[j])

\* 等价的「计数」写法：临界区里的进程数 <= 1。
AtMostOneInCS == Cardinality({i \in ProcSet : inCS[i]}) <= 1

\* 活性（这里**故意不查**）：「进程 1 无限次进入临界区」。
\* 直觉上似乎该成立，但 PlusCal 的 fair 只对整个 Next 析取加公平性，
\* 并不保证「单个进程」不被饿死——TLC 能构造出进程 2 一直霸占锁、进程 1
\* 永远卡在 await 的反例。要证每条进程的活性，需要给每个进程单独的公平性，
\* 这是更深的话题。本章把 MutEx（安全性）查绿即可。
P1InfinitelyOften == []<>(inCS[1])
=============================================================================
