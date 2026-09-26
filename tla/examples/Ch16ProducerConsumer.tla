-------------------------- MODULE Ch16ProducerConsumer --------------------------
\* 第 16 章：生产者-消费者 / 有界缓冲区——并发数据流的经典正确性。
\* 一个生产者往有限容量缓冲区放「编号物品」，一个消费者从队头取。
\* 要证明的性质（全是安全性，TLC 穷举所有放/取交错）：
\*   · 缓冲区永不超过容量 Cap（不溢出）；
\*   · 消费件数永不超过生产件数（不凭空消费）；
\*   · 缓冲区内容恰好是「已生产未消费」那段连续编号（不丢、不乱序）。
\*
\* ⚠ 收敛要点：prod/cons 若可无限增长，状态空间就无限、TLC 永远跑不完。
\*   这里把「总产量」钉成有限的 MaxItems=6（TLC 只能查有限模型），
\*   并加一个 Idle 动作让系统在生产完毕、缓冲清空后合法地「停下」，避免死锁。

EXTENDS Integers, Sequences, TLC

CONSTANT Cap                           \* 缓冲区容量，.cfg 里给 3
MaxItems == 6                          \* 总共生产多少件（有限，保证 TLC 收敛）

VARIABLES buf, prod, cons              \* 缓冲区（序列）、已生产数、已消费数
vars == <<buf, prod, cons>>

Init ==
  /\ buf  = <<>>
  /\ prod = 0
  /\ cons = 0

\* 生产：缓冲区没满、且还没生产够 MaxItems 时，放入下一个编号 prod+1。
Produce ==
  /\ Len(buf) < Cap
  /\ prod < MaxItems
  /\ prod' = prod + 1
  /\ buf'  = Append(buf, prod + 1)
  /\ cons' = cons

\* 消费：缓冲区非空时，从队头取走一个。
Consume ==
  /\ Len(buf) > 0
  /\ cons' = cons + 1
  /\ buf'  = Tail(buf)
  /\ prod' = prod

\* 终止态：生产完毕且缓冲已空，原地踏步（让行为可无限延伸，TLC 不报死锁）。
Idle ==
  /\ prod = MaxItems
  /\ buf = <<>>
  /\ UNCHANGED vars

Next == Produce \/ Consume \/ Idle
Spec == Init /\ [][Next]_vars

\* --- 性质 -----------------------------------------------------------
TypeOK ==
  /\ buf  \in Seq(1..MaxItems)          \* buf 是 1..6 中元素组成的有限序列
  /\ prod \in 0..MaxItems
  /\ cons \in 0..MaxItems

NoOverflow      == Len(buf) <= Cap                 \* 不溢出
NoOverConsume   == cons <= prod                    \* 消费不超过生产
CountMatch      == Len(buf) = prod - cons          \* 缓冲件数 = 生产 - 消费

\* 缓冲区里恰好是 cons+1, cons+2, ..., prod 这段连续编号，且顺序正确。
BufContent == buf = [i \in 1..(prod - cons) |-> cons + i]
=============================================================================
