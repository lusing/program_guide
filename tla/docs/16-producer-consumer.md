# 16 · 生产者-消费者：有界缓冲区

对应示例：`../examples/Ch16ProducerConsumer.tla`

并发数据流的经典正确性问题：一个生产者往**有限容量**缓冲区放编号物品，一个消费者从
队头取。要证明三条安全性：缓冲区**不溢出**、消费者**不凭空消费**、缓冲区内容**恰好是
已生产未消费的那段连续编号**（不丢、不乱序）。

本机实测（`Cap = 3`）：`32 states generated, 22 distinct states found ...
No error has been found.`

## 收敛要点：把无界变有界

`prod`/`cons`（已生产/已消费数）若可无限增长，状态空间就**无限**、TLC 永远跑不完
（第 09 章）。本章用两招把它钉成有限：

1. 把"总产量"钉成有限的 `MaxItems = 6`；
2. 加一个 `Idle` 动作，让系统在生产完毕、缓冲清空后**合法地停下**，避免 `Deadlock`。

> TLC 只能查有限模型——这是它的根本边界。建模时永远要问："我的状态空间有限吗？"
> 无限就靠 `CONSTRAINT` 截断、或把常量调小、或像本章那样限定总量。

## 规格

```tla
EXTENDS Integers, Sequences, TLC
CONSTANT Cap                 \* 缓冲区容量，.cfg 给 3
MaxItems == 6                \* 总产量（有限，保证收敛）

VARIABLES buf, prod, cons
vars == <<buf, prod, cons>>
Init == /\ buf = <<>> /\ prod = 0 /\ cons = 0

Produce ==                   \* 缓冲区没满、且没生产够时，放入 prod+1
  /\ Len(buf) < Cap
  /\ prod < MaxItems
  /\ prod' = prod + 1
  /\ buf'  = Append(buf, prod + 1)
  /\ cons' = cons

Consume ==                   \* 缓冲区非空时，从队头取走一个
  /\ Len(buf) > 0
  /\ cons' = cons + 1
  /\ buf'  = Tail(buf)
  /\ prod' = prod

Idle ==                      \* 终止态：生产完毕且缓冲空，原地踏步（避免死锁）
  /\ prod = MaxItems /\ buf = <<>> /\ UNCHANGED vars

Next == Produce \/ Consume \/ Idle
Spec == Init /\ [][Next]_vars
```

`buf` 是一个**序列**：`Append` 在队尾放、`Tail` 从队头取，天然的 FIFO 队列。
`Produce` 和 `Consume` 的守卫（`Len(buf) < Cap`、`Len(buf) > 0`）就是"满了不能再放、
空了不能再取"——溢出和下溢都被守卫挡死。

## 性质

```tla
TypeOK ==
  /\ buf  \in Seq(1..MaxItems)     \* buf 是 1..6 中元素组成的有限序列
  /\ prod \in 0..MaxItems
  /\ cons \in 0..MaxItems

NoOverflow      == Len(buf) <= Cap            \* 不溢出
NoOverConsume   == cons <= prod               \* 消费不超过生产
CountMatch      == Len(buf) = prod - cons     \* 缓冲件数 = 生产 - 消费
BufContent      == buf = [i \in 1..(prod - cons) |-> cons + i]
```

最漂亮的是 `BufContent`：它断言缓冲区里**恰好**是 `cons+1, cons+2, …, prod` 这段连续
编号、且顺序正确。这一条同时排除了"丢物品""重复""乱序"三种 bug——是个很强的不变式。
能写出这么强的性质，正是规格思维的功力。

`.cfg`：

```text
INIT Init
NEXT Next
CONSTANT Cap = 3
INVARIANT TypeOK
INVARIANT NoOverflow
INVARIANT NoOverConsume
INVARIANT CountMatch
INVARIANT BufContent
```

TLC 穷举所有"放/取"交错（22 个不同状态），五条不变式全部成立。

## `Seq(S)` 是什么

`Seq(S)` 表示"S 中元素组成的**所有**有限序列"的集合（无限集）。`buf \in Seq(1..6)`
只是检查"`buf` 是一个元素都在 1..6 里的有限序列"，TLC 能做这个成员判断而无需枚举整个
无限集。

## 想证活性（不饿死）

本章只证安全性。"生产的东西终将被消费"是活性，需要给 `Spec` 加公平性并对
`Produce`/`Consume` 做 per-action 公平假设，再用 `PROPERTY <>(...)`。和第 11/14 章
一样，留作练习——先记住：**有界缓冲的正确性核心是那几条安全不变式**。

---
上一章：[15 · 银行转账](15-bank-transfer.md) ｜ 下一章：[17 · 竞态条件](17-race-condition.md) ｜ 返回：[README](../README.md)
