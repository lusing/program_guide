# 06 · 时序算子与公平性

对应示例：`../examples/Ch06Temporal.tla`

这一章是 TLA+ 区别于普通断言的地方：它能谈论**整条无限行为**上的性质。核心是几个
时序算子，和理解它们之后，第 01 章埋的那个伏笔（"为什么不加公平性，活性会失败"）
就豁然开朗了。

本机实测：`Progress(4) ... 4 distinct states found ... No error has been found.`

## 时序算子

| 写法 | 读法 | 含义 |
|---|---|---|
| `[]P` | always P / box P | 在行为的**每个**状态都成立 |
| `<>P` | eventually P / diamond P | 在行为里**某个**时刻成立 |
| `[]<>P` | infinitely often P | 无限次成立 |
| `<>[]P` | eventually always P | 从某刻起一直成立 |
| `[A]_v` | — | 等价于 `A \/ (v' = v)`：要么走一步 A，要么 v 不变（空转） |
| `<<A>>_v` | — | 等价于 `A /\ (v' # v)`：走一步 A 且确实改变了 v |
| `WF_v(A)` | weak fairness | 弱公平：若 A **一直**使能，则它终将发生 |
| `SF_v(A)` | strong fairness | 强公平：若 A **无限次**使能，则它终将发生 |

`v` 是变量元组（如 `<<n>>`）。`[A]_v` 的下标 `_v` 圈定了"允许空转的变量范围"。

## 为什么需要 `[A]_v` 和空转

回忆第 01 章：TLA+ 里**行为是无限的**。系统"停了"被建模成"所有变量永远不变"
（stuttering，空转）。`[Next]_vars` 的意思是"每一步要么走 Next，要么 vars 全不变"。
这样，一个跑完就停的系统也能对应一条无限行为（后半段全是空转）。

`Spec` 的标准形状：

```tla
Spec == Init /\ [][Next]_vars
```

读作："起点满足 Init，且此后每一步都是 Next 或空转。"

## 公平性：排除"无限期赖着不走"的行为

问题来了：`[Next]_vars` **允许**永远空转。所以"系统卡在初始状态、一步都不走"也是一条
合法行为。对**安全性**（`[]` 性质）这无所谓——空转不会让坏事发生。但对**活性**
（`<>` 性质）就是灾难：如果系统可以永远不动，那"终将到达某状态"就不成立。

**公平性**就是用来排除这种"耍赖"行为的额外假设。

```tla
SpecNoFair == Init /\ [][Next]_vars                  \* 可以永远卡在 n=0
SpecFair   == Init /\ [][Next]_vars /\ WF_vars(Next) \* 只要 Next 一直使能就终会发生
```

- **弱公平 `WF_vars(Next)`**：如果 `Next` 从某刻起**一直**使能，那它终将发生。
  排除"动作一直可以走却永远不走"的行为。
- **强公平 `SF_vars(Next)`**：如果 `Next` **无限次**使能（哪怕中间被禁用），那它终将
  发生。比弱公平更强，用于动作会被反复禁用的场景。

## 本章的例子

```tla
VARIABLES n
vars == <<n>>
Init == n = 0
Tick == /\ n < 3 /\ n' = n + 1
Idle == /\ n = 3 /\ n' = n          \* 到顶后的自环
Next == Tick \/ Idle
```

为什么要 `Idle`？因为如果只写 `Next == Tick`，到 `n=3` 时 `Tick` 被禁用、没有后继
动作，TLC 会报 **`Deadlock reached`**（行为断了）。`Idle` 让系统在 `n=3` 合法地
"原地停住"，行为得以无限延伸。这是写 TLA+ 规格的常见手法：**任何会"跑完"的系统，
都要给终态一个自环动作**。

性质：

```tla
TypeOK   == n \in 0..3
Safety   == [](n <= 3)        \* 安全性：永不超过 3（无需公平性）
Progress == <>(n = 3)         \* 活性：终将数到 3（**只有 SpecFair 下成立**）
```

`.cfg` 用 `SPECIFICATION SpecFair`（不是 INIT/NEXT），因为要查时序性质 `Safety`、
`Progress`：

```text
SPECIFICATION SpecFair
INVARIANT TypeOK
INVARIANT EnabledFact
PROPERTY Safety
PROPERTY Progress
```

> `INVARIANT` 用于状态不变式，`PROPERTY` 用于一般时序公式。`Safety == [](n<=3)` 既
> 能当 PROPERTY，其等价的状态层面 `n<=3` 也能当 INVARIANT。活性 `Progress` 必须用
> PROPERTY。

## ENABLED：动作此刻使能吗

```tla
EnabledFact == ENABLED Tick <=> (n < 3)
```

`ENABLED A` 是一个**状态层面**的算子，表示"动作 A 在当前状态能不能发生"。这里：
`Tick` 使能当且仅当 `n < 3`。`ENABLED` 在写"系统永不卡死"（`[]ENABLED Next`）这类
性质时很有用。

## 关键对比：SpecNoFair 会怎样

如果你把 cfg 改成 `SPECIFICATION SpecNoFair` 再查 `Progress`，TLC 会给出反例：一条
**永远停在 `n=0`** 的行为——因为不加公平性，无限空转是合法的，`<>(n=3)` 自然不成立。
这正是公平性的全部意义。建议亲手试一次，印象最深。

---
上一章：[05 · 状态机三件套](05-state-machine.md) ｜ 下一章：[07 · 安全性 vs 活性](07-safety-liveness.md) ｜ 返回：[README](../README.md)
