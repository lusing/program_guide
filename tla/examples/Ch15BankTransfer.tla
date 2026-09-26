---------------------------- MODULE Ch15BankTransfer ----------------------------
\* 第 15 章：银行转账——「守恒类」不变式的典型实战。
\* 这是 Practical TLA+ 风格的例子：账户之间转账，要保证两条铁律：
\*   1. 余额永不为负（不能透支）；
\*   2. 所有账户的总钱数恒定（转账只搬运、不凭空创造或销毁）。
\* TLC 会穷举所有转账顺序，替我们确认这两条在每个可达状态都成立。

EXTENDS Integers, Sequences, FiniteSets, TLC

\* 固定三个账户（写死便于把「求和」讲清楚）；初值各 100，总额 300。
Accts    == {"A", "B", "C"}
AccSeq   == <<"A", "B", "C">>          \* 求和用的有序版本
InitBal  == 100
MaxAmt   == 20                          \* 单笔转账上限，保证状态空间有限

VARIABLES bal                           \* bal 是「账户 -> 余额」的函数
vars == <<bal>>

Init == bal = [a \in Accts |-> InitBal]

\* 对一个「账户->数」的函数按 AccSeq 顺序求和（序列折叠的写法，第 03 章函数 + 递归）。
RECURSIVE SumSeq(_, _)
SumSeq(f, s) ==
  IF s = <<>> THEN 0 ELSE f[Head(s)] + SumSeq(f, Tail(s))

Total == SumSeq(bal, AccSeq)

\* 从 from 转 amt 到 to：要求是不同账户、金额为正、且转出方余额充足。
Transfer(from, to, amt) ==
  /\ from # to
  /\ amt \in 1..MaxAmt
  /\ bal[from] >= amt                   \* 余额充足才允许（这条守卫正是「不透支」的来源）
  /\ bal' = [bal EXCEPT ![from] = @ - amt, ![to] = @ + amt]   \* @ 表示「该位置原值」

\* 一步 = 任选 from、to、amt 做一次合法转账。
Next == \E from \in Accts, to \in Accts, amt \in 1..MaxAmt : Transfer(from, to, amt)

Spec == Init /\ [][Next]_vars

\* --- 性质 -----------------------------------------------------------
TypeOK     == bal \in [Accts -> 0..(Cardinality(Accts) * InitBal)]
NoNegative == \A a \in Accts : bal[a] >= 0                 \* 铁律 1：不透支
MoneyConserved == Total = Cardinality(Accts) * InitBal     \* 铁律 2：总额恒为 300
=============================================================================
