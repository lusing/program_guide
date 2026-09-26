# 13 · 水壶问题（Die Hard）：把 TLC 当求解器

对应示例：`../examples/Ch13DieHard.tla`

这是 Lamport《Specifying Systems》和 TLC 教程里的招牌例子，也最能说明模型检查的思维
方式：**想找一个能达到某目标的操作序列？把"目标永远达不到"写成不变式，让 TLC 去证伪
——它给出的反例就是你要的解法。**

> 题目：一个 3 加仑小壶、一个 5 加仑大壶，水可无限取/倒。能否让大壶里正好有 4 加仑？
> （电影《虎胆龙威 3》里的拆弹谜题。）因为是"演示错误"示例，`run-all.sh` 期望 TLC
> **报违反**——找到解才算通过。

## 规格

```tla
EXTENDS Integers, TLC
VARIABLES small, big                 \* 小壶、大壶当前水量

TypeOK == /\ small \in 0..3 /\ big \in 0..5
Init   == /\ small = 0 /\ big = 0

FillSmall  == /\ small' = 3 /\ big' = big
FillBig    == /\ small' = small /\ big' = 5
EmptySmall == /\ small' = 0 /\ big' = big
EmptyBig   == /\ small' = small /\ big' = 0

Small2Big ==                        \* 小壶往大壶倒
  IF big + small <= 5
    THEN /\ big' = big + small /\ small' = 0
    ELSE /\ big' = 5 /\ small' = big + small - 5

Big2Small ==                        \* 大壶往小壶倒
  IF small + big <= 3
    THEN /\ small' = small + big /\ big' = 0
    ELSE /\ small' = 3 /\ big' = small + big - 3

Next == \/ FillSmall \/ FillBig \/ EmptySmall \/ EmptyBig
        \/ Small2Big \/ Big2Small

Spec == Init /\ [][Next]_<<small, big>>

NotSolved == big # 4                \* 声称「大壶永远不可能正好 4」——这是假的
```

六个动作穷尽了所有合法倒水操作。`NotSolved` 是一条**假**的不变式：它声称大壶永远到不了
4 加仑。TLC 会努力证伪它，而证伪的过程就是**搜索一条到达 `big = 4` 的操作序列**。

`.cfg`：

```text
INIT Init
NEXT Next
INVARIANT NotSolved
```

## TLC 找到的解法（本机实测原文）

```text
Error: Invariant NotSolved is violated.
Error: The behavior up to this point is:
State 1: <Initial predicate>   big = 0  small = 0
State 2: <FillBig>             big = 5  small = 0
State 3: <Big2Small>           big = 2  small = 3
State 4: <EmptySmall>          big = 2  small = 0
State 5: <Big2Small>           big = 0  small = 2
State 6: <FillBig>             big = 5  small = 2
State 7: <Big2Small>           big = 4  small = 3
```

读这条反例 = 读谜题答案：

1. 灌满大壶（5,0）
2. 大壶倒满小壶 → 大壶剩 2（2,3）
3. 倒空小壶（2,0）
4. 把大壶那 2 加仑倒进小壶（0,2）
5. 再灌满大壶（5,2）
6. 大壶往小壶倒，小壶还能装 1（它已有 2、容量 3）→ 大壶剩 **4**（4,3）✅

因为 TLC 用广度优先搜索，这条反例是**步数最少**的解法之一（6 步）。

## 这个例子的方法论价值

它把"模型检查"和"求解器"统一了：**搜索 = 证伪**。

- 想问"能不能到达某状态"→ 把"永远到不了"写成不变式，TLC 报违反 = 能到达，反例 = 路径。
- 想问"某 bug 可不可能发生"→ 把"bug 永不发生"写成不变式，TLC 报违反 = bug 存在，
  反例 = 复现步骤（第 08、17 章）。
- TLC 不报违反（`No error has been found`）= 在**所有**可达状态/路径里性质都成立 =
  在你给定的有限模型范围内，**证明**了它。

> 注意边界：TLC 只检查你给定的**有限**模型（这里水量天然有界，所以是完整的）。它不是
> 对所有 N 都成立的数学证明——那需要 TLAPS 证明器或第 19 章提到的工具。但对"具体配置下
> 有没有 bug"，TLC 的穷举就是确凿的。

试试改题：把 `NotSolved` 改成 `small # 4`（小壶能否量出 4？小壶容量才 3，应永远到不了
→ TLC 报 `No error`，即证明不可能），或 `big # 1`（大壶量 1 加仑）再跑，感受一下。

---
上一章：[12 · 模块化与 INSTANCE](12-modules-instance.md) ｜ 下一章：[14 · 纯 TLA+ 互斥](14-mutual-exclusion.md) ｜ 返回：[README](../README.md)
