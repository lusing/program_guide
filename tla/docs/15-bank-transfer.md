# 15 · 银行转账：守恒类不变式

对应示例：`../examples/Ch15BankTransfer.tla`

这是 *Practical TLA+* 风格的例子：账户之间转账，要保证两条铁律——**余额永不为负**
（不透支）和**总钱数恒定**（转账只搬运、不创造不销毁）。TLC 会穷举所有转账顺序，确认
这两条在每个可达状态都成立。

本机实测：`5,082,841 states generated, 45,451 distinct states found ...
No error has been found.`，耗时约 **8 秒**。这是本教程最"重"的例子，也最能体现穷举的
威力：它检查了**五百万**个状态转移，而你一个都没手动跑过。

## 规格

```tla
EXTENDS Integers, Sequences, FiniteSets, TLC

Accts    == {"A", "B", "C"}          \* 三个账户（写死，便于讲清「求和」）
AccSeq   == <<"A", "B", "C">>        \* 求和用的有序版本
InitBal  == 100                      \* 初值各 100，总额 300
MaxAmt   == 20                       \* 单笔上限，保证状态空间有限

VARIABLES bal                        \* bal 是「账户 -> 余额」的函数
vars == <<bal>>
Init == bal = [a \in Accts |-> InitBal]

\* 对「账户->数」的函数按 AccSeq 顺序求和（序列折叠）
RECURSIVE SumSeq(_, _)
SumSeq(f, s) ==
  IF s = <<>> THEN 0 ELSE f[Head(s)] + SumSeq(f, Tail(s))
Total == SumSeq(bal, AccSeq)

Transfer(from, to, amt) ==
  /\ from # to
  /\ amt \in 1..MaxAmt
  /\ bal[from] >= amt               \* 守卫：余额充足才允许（这条正是「不透支」的来源）
  /\ bal' = [bal EXCEPT ![from] = @ - amt, ![to] = @ + amt]

Next == \E from \in Accts, to \in Accts, amt \in 1..MaxAmt :
          Transfer(from, to, amt)
Spec == Init /\ [][Next]_vars
```

要点：

- `bal` 是函数 `Accts -> Nat`，`bal[a]` 是账户 a 的余额。
- `Transfer` 的守卫 `bal[from] >= amt` 是**关键**：正是它保证了不透支。把它删掉，TLC
  立刻能找出一个余额变负的状态。
- `[bal EXCEPT ![from] = @ - amt, ![to] = @ + amt]` 一步同时改两个账户，`@` 表示"该
  位置的原值"。两个改动在**同一动作**里发生，所以不会出现"扣了款没到账"的中间态。
- `\E from, to, amt : ...` 穷举所有"谁转给谁、转多少"的组合——这就是并发/不确定性。

## 求和的写法：序列折叠

TLA+ 没有内置的"对集合求和"。常用技巧是**把集合排成序列，再递归折叠**：

```tla
RECURSIVE SumSeq(_, _)
SumSeq(f, s) == IF s = <<>> THEN 0 ELSE f[Head(s)] + SumSeq(f, Tail(s))
```

`SumSeq(bal, <<"A","B","C">>)` = `bal["A"] + bal["B"] + bal["C"]`。`RECURSIVE` 声明
让 TLC 接受这个递归定义；因为 `AccSeq` 是固定有限序列，递归必然终止。

> 这就是为什么本章把账户写死成三个、并提供 `AccSeq`：求和需要一个**确定的顺序**。
> 对任意 `CONSTANT` 集合求和要借助 `CHOOSE` 之类，复杂且易踩坑；教学例子里写死更清楚。

## 性质

```tla
TypeOK         == bal \in [Accts -> 0..(Cardinality(Accts) * InitBal)]
NoNegative     == \A a \in Accts : bal[a] >= 0                 \* 铁律 1
MoneyConserved == Total = Cardinality(Accts) * InitBal         \* 铁律 2：总额恒为 300
```

`.cfg`：

```text
INIT Init
NEXT Next
INVARIANT TypeOK
INVARIANT NoNegative
INVARIANT MoneyConserved
```

`MoneyConserved` 是典型的**守恒不变式**：无论转账顺序如何交错，总额永远是 300。这类
"某个量恒定"的性质，是验证金融/库存/资源分配系统的核心。

## 状态空间为什么会到五百万

`MaxAmt = 20`、3 个账户、每个账户余额 0..300，加上"谁转给谁转多少"的组合，转移数巨大。
但**不同状态**只有 45,451 个（余额三元组的可达组合），TLC 用指纹去重，8 秒跑完。

> 这给你两个直觉：① TLC 真的在穷举，不是抽样；② 状态空间对参数极其敏感。若把
> `MaxAmt` 调到 50、`InitBal` 调到 1000，状态数会暴涨。**调小常量是控制 TLC 运行时
> 的首要手段**（第 09 章的 `CONSTRAINT` 是另一手段）。

## 动手验证 bug

把 `Transfer` 里的守卫 `bal[from] >= amt` 删掉，重跑 `./run-all.sh 15`：TLC 会立刻
报 `Invariant NoNegative is violated`，并打印一条让某账户透支的转账序列。这就是 TLA+
的日常——**改一行、看 TLC 抓不抓得到**，比读一百遍代码都靠谱。

---
上一章：[14 · 纯 TLA+ 互斥](14-mutual-exclusion.md) ｜ 下一章：[16 · 生产者-消费者](16-producer-consumer.md) ｜ 返回：[README](../README.md)
